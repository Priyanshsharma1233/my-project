package com.myapp;

import jakarta.websocket.*;
import jakarta.websocket.server.PathParam;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@ServerEndpoint("/presence/{username}")
public class PresenceWebSocket {

    // ✅ username -> session map
    private static Map<String, Session> onlineUsers = new ConcurrentHashMap<>();

    @OnOpen
    public void onOpen(Session session, @PathParam("username") String username) {
        onlineUsers.put(username, session);
        System.out.println(username + " came online. Total: " + onlineUsers.size());

        // ✅ Tell everyone this user is online
        broadcast("{\"type\":\"online\",\"user\":\"" + username + "\"}", username);

        // ✅ Send list of all currently online users to new user
        // This fixes online status not showing after refresh
        StringBuilder sb = new StringBuilder("{\"type\":\"onlineList\",\"users\":[");
        boolean first = true;
        for (String user : onlineUsers.keySet()) {
            if (!user.equals(username)) {
                if (!first) sb.append(",");
                sb.append("\"").append(user).append("\"");
                first = false;
            }
        }
        sb.append("]}");

        try {
            session.getBasicRemote().sendText(sb.toString());
        } catch (IOException e) {
            System.out.println("Error sending onlineList: " + e.getMessage());
        }
    }

    @OnMessage
    public void onMessage(String message, @PathParam("username") String fromUsername) {
        // ✅ Parse without org.json — manual extraction
        try {
            if (message.contains("\"type\":\"typing\"")) {
                String to = extractValue(message, "to");
                if (to != null) {
                    Session target = onlineUsers.get(to);
                    if (target != null && target.isOpen()) {
                        target.getBasicRemote().sendText(message);
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("Presence onMessage error: " + e.getMessage());
        }
    }

    @OnClose
    public void onClose(Session session, @PathParam("username") String username) {
        onlineUsers.remove(username);
        System.out.println(username + " went offline. Total: " + onlineUsers.size());

        // ✅ Tell everyone this user is offline
        broadcast("{\"type\":\"offline\",\"user\":\"" + username + "\"}", username);
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        System.out.println("Presence error: " + throwable.getMessage());
    }

    // ✅ Broadcast to all except one user
    private void broadcast(String message, String excludeUser) {
        for (Map.Entry<String, Session> entry : onlineUsers.entrySet()) {
            if (!entry.getKey().equals(excludeUser) && entry.getValue().isOpen()) {
                try {
                    entry.getValue().getBasicRemote().sendText(message);
                } catch (IOException e) {
                    System.out.println("Broadcast error: " + e.getMessage());
                }
            }
        }
    }

    // ✅ Extract JSON value without org.json
    private String extractValue(String json, String key) {
        String search = "\"" + key + "\":\"";
        int start = json.indexOf(search);
        if (start == -1) return null;
        start += search.length();
        int end = json.indexOf("\"", start);
        if (end == -1) return null;
        return json.substring(start, end);
    }

    // ✅ Public check
    public static boolean isOnline(String username) {
        return onlineUsers.containsKey(username);
    }
}
