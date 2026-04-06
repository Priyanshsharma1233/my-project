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

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            DbController db = new DbController();
            String currentUser = (String) request.getSession().getAttribute("username");

            if (currentUser == null) {
                response.getWriter().write("[]");
                return;
            }

            ResultSet rs = db.getReceiverName(currentUser);
            ArrayList<String> receivers = new ArrayList<>();

            while (rs.next()) {
                // ✅ Fixed — query returns "receiver, sender"
                String receiver = rs.getString("receiver");
                String sender = rs.getString("sender");

                if (!sender.equalsIgnoreCase(currentUser) && !receivers.contains(sender)) {
                    receivers.add(sender);
                }
                if (!receiver.equalsIgnoreCase(currentUser) && !receivers.contains(receiver)) {
                    receivers.add(receiver);
                }
            }
            Gson gson = new GsonBuilder().setPrettyPrinting().create();
            String json = gson.toJson(receivers);
            response.getWriter().write(json);

        } catch (Exception e) {
            System.out.println("Exception while getting usernames: " + e);
            // ✅ Return empty array on error
            response.getWriter().write("[]");
        }
    }
}