package com.myapp;

import com.myapp.Database.DbController;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/validateUser")
public class ValidateUser extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String username = req.getParameter("username");
        resp.setContentType("text/plain");
        resp.setCharacterEncoding("UTF-8");

        // ✅ Check if username parameter is empty
        if (username == null || username.trim().isEmpty()) {
            resp.getWriter().write("");
            return;
        }

        try {
            DbController obj = new DbController();
            String user = obj.getUsers(username.trim());
            System.out.println("Database user: " + user);

            // ✅ Write empty string instead of null if user not found
            resp.getWriter().write(user != null ? user : "");

        } catch (Exception e) {
            System.out.println("Exception in validateUser: " + e);
            resp.getWriter().write("");
        }
    }
}