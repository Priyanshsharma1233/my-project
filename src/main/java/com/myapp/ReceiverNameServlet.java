package com.myapp;

import com.myapp.Database.DbController;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.util.ArrayList;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

@WebServlet("/getReceivers")
public class ReceiverNameServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        System.out.println("Called");
        try {
            DbController db = new DbController();
            String currentUser = (String) request.getSession().getAttribute("username");

            // Fetch receiver names related to current user
            ResultSet rs = db.getReceiverName(currentUser);

            ArrayList<String> receivers = new ArrayList<>();

            while (rs.next()) {
                String sender = rs.getString(1);
                String receiver = rs.getString(2);

                // ✅ Add only names that are NOT the current user
                if (!sender.equalsIgnoreCase(currentUser) && !receivers.contains(sender)) {
                    receivers.add(sender);
                }
                if (!receiver.equalsIgnoreCase(currentUser) && !receivers.contains(receiver)) {
                    receivers.add(receiver);
                }
            }

            // Convert to JSON and send response
            Gson gson = new GsonBuilder().setPrettyPrinting().create();
            String json = gson.toJson(receivers);

            response.setContentType("application/json");
            response.getWriter().write(json);

        } catch (Exception e) {
            System.out.println("Exception while getting usernames: " + e);
        }
    }
}
