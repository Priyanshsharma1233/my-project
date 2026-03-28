package com.myapp;

import com.myapp.Database.DbController;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/handleLogin")
public class login extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        DbController dbObj = new DbController();
        String name = dbObj.validateUser(username, password);

        if (name != null) {
            // ✅ Valid user
            HttpSession session = request.getSession();
            session.setAttribute("username", username);
            session.setAttribute("name", name);
            response.sendRedirect("home.jsp");
        } else {
            // ❌ Invalid user → return to index.jsp (login page)
            request.setAttribute("errorMessage", "Invalid username or password!");
            RequestDispatcher rd = request.getRequestDispatcher("index.jsp");
            rd.forward(request, response);
        }
    }
}
