package com.myapp;

import jakarta.websocket.*;
import jakarta.websocket.server.PathParam;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@ServerEndpoint("/presence/{username}")
public class PresenceWebSocket {

    // username -> session
    private static Map<String, Session> onlineUsers = new ConcurrentHashMap<>();

    @OnOpen
    public void onOpen(Session session, @PathParam("username") String username) {
        onlineUsers.put(username, session);
        System.out.println(username + " is online");
        // Notify all others that this user is online
        broadcast("{\"type\":\"online\",\"user\":\"" + username + "\"}", username);
    }

    @OnMessage
    public void onMessage(String message, @PathParam("username") String username) {
        // Relay typing indicator to specific user
        // Message format: {"type":"typing","to":"receiver","from":"sender"}
        try {
            org.json.JSONObject json = new org.json.JSONObject(message);
            String type = json.getString("type");
            String to = json.getString("to");

            Session targetSession = onlineUsers.get(to);
            if (targetSession != null && targetSession.isOpen()) {
                targetSession.getBasicRemote().sendText(message);
            }
        } catch (Exception e) {
            System.out.println("Presence message error: " + e.getMessage());
        }
    }

    @OnClose
    public void onClose(@PathParam("username") String username) {
        onlineUsers.remove(username);
        System.out.println(username + " is offline");
        // Notify all others that this user is offline
        broadcast("{\"type\":\"offline\",\"user\":\"" + username + "\"}", username);
    }

    @OnError
    public void onError(Throwable throwable) {
        System.out.println("Presence error: " + throwable.getMessage());
    }

    // ✅ Check if user is online
    public static boolean isOnline(String username) {
        return onlineUsers.containsKey(username);
    }

    // ✅ Broadcast to all except sender
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
}
