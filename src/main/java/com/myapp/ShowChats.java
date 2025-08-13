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

public class ShowChats extends HttpServlet{
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String sender = (String)request.getSession().getAttribute("username");
        String receiver = (String)request.getSession().getAttribute("receiver");
        try{
            DbController dbController = new DbController();
            List<Message> messages =dbController.getMessage(sender,receiver);
            Gson gson =new GsonBuilder().setPrettyPrinting().create();
            String json =gson.toJson(messages);
            response.setContentType("Application/json");
            response.getWriter().write(json);
        }catch (Exception e){
            System.out.println("Error in get message servlet"+e.getMessage());
        }
    }

}
