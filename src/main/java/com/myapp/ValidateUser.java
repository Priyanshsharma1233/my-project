package com.myapp;

import com.myapp.Database.DbController;
import jakarta.servlet.RequestDispatcher;
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
        DbController obj = new DbController();
        try{
            String user = obj.getUsers(username);
            System.out.println("Database user " + user);
            resp.setContentType("text/html");
            resp.getWriter().write(user);
        } catch(Exception e) {
            System.out.println("Exception is " + e);
        }


    }
}
