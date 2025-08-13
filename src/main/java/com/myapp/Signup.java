package com.myapp;
import com.myapp.Database.DbController;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.Timestamp;

@WebServlet("/handleSignup")

public class Signup extends HttpServlet {

        protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
            String name = request.getParameter("name");
            String username = request.getParameter("username");
            String password = request.getParameter("password");

            DbController dbObj = new DbController();
            int status = dbObj.createUser(name, username, password);

            if (status==1)
                response.sendRedirect("index.jsp");
            else if(status == 2) {
                request.setAttribute("errorMessage", "Username already exist. try other user name");
                RequestDispatcher rd = request.getRequestDispatcher("signup.jsp");
                rd.forward(request, response);
            }
            else {
                request.setAttribute("errorMessage", "Something want wrong");
                RequestDispatcher rd = request.getRequestDispatcher("signup.jsp");
                rd.forward(request, response);
            }
        }

    public static class Message {
        public int msgid;
        public String sender;
        public String receiver;
        public String message;
        Timestamp timestamp;

        public Message(String sender,String receiver,String message){
            this.sender = sender;
            this.receiver = receiver;
            this.message = message;
        }
    }

    @WebServlet("/logout")
    public static class LogoutServlet extends HttpServlet{
        @Override
        protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
            try{
                HttpSession session  = request.getSession();
                session.invalidate();
                response.sendRedirect("/Project1");

            } catch(Exception e){
                System.out.println();
            }
        }
    }
}
