package com.myapp;

import com.myapp.Database.DbController;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/sendWelcomeMessage")
public class SendMessage extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String Sender = (String)req.getSession().getAttribute("username");
        String receiver = req.getParameter("receiver");
        String message = req.getParameter("message");
        try{
            DbController db = new DbController();
            db.insertMessage(new Message(Sender,receiver,message));
            System.out.println("message saved");
        }
        catch(Exception e){
            System.out.println("Error in insert message"+e.getMessage());
        }
    }
}
