package com.myapp;
import jakarta.websocket.*;
import jakarta.websocket.server.PathParam;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

    @ServerEndpoint("/signal/{roomId}")
    public class SignalingEndpoint {

        // roomId -> list of sessions in that room
        private static Map<String, List<Session>> rooms = new ConcurrentHashMap<>();

        @OnOpen
        public void onOpen(Session session, @PathParam("roomId") String roomId) {
            rooms.computeIfAbsent(roomId, k -> Collections.synchronizedList(new ArrayList<>()))
                    .add(session);
            System.out.println("User joined room: " + roomId);
        }

        @OnMessage
        public void onMessage(String message, Session senderSession,
                              @PathParam("roomId") String roomId) {
            List<Session> peers = rooms.getOrDefault(roomId, new ArrayList<>());

            // Relay message to all OTHER peers in the same room
            for (Session peer : peers) {
                if (peer.isOpen() && !peer.getId().equals(senderSession.getId())) {
                    try {
                        peer.getBasicRemote().sendText(message);
                    } catch (IOException e) {
                        System.out.println("Error sending signal: " + e.getMessage());
                    }
                }
            }
        }

        @OnClose
        public void onClose(Session session, @PathParam("roomId") String roomId) {
            List<Session> peers = rooms.getOrDefault(roomId, new ArrayList<>());
            peers.remove(session);
            if (peers.isEmpty()) rooms.remove(roomId);
            System.out.println("User left room: " + roomId);
        }

        @OnError
        public void onError(Session session, Throwable throwable) {
            System.out.println("WebSocket error: " + throwable.getMessage());
        }
    }

