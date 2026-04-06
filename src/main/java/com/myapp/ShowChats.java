package com.myapp;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.myapp.Database.DbController;
import jakarta.servlet.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

@WebServlet("/showChats")
public class ShowChats extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String sender = (String) request.getSession().getAttribute("username");
        String receiver = (String) request.getSession().getAttribute("receiver");

        // ✅ Return empty array if no receiver selected
        if (sender == null || receiver == null) {
            response.getWriter().write("[]");
            return;
        }

        try {
            DbController dbController = new DbController();
            List<Message> messages = dbController.getMessage(sender, receiver);
            Gson gson = new GsonBuilder().setPrettyPrinting().create();
            String json = gson.toJson(messages);
            response.getWriter().write(json);
        } catch (Exception e) {
            System.out.println("Error in get message servlet: " + e.getMessage());
            // ✅ Return empty array on error
            response.getWriter().write("[]");
        }
    }
}