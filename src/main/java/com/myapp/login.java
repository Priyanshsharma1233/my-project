package com.myapp;
import com.myapp.Database.DbController;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/handleLogin")
public class login extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException,IOException {
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        DbController dbObj = new DbController();
        String name = dbObj.validateUser(username,password);

        HttpSession session = request.getSession();
        session.setAttribute("username", username);
        session.setAttribute("name", name);
        response.sendRedirect("home.jsp");
    }
}