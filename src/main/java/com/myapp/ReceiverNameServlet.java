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
protected void doPost(HttpServletRequest request, HttpServletResponse response)throws ServletException,IOException{
    System.out.println("Called");
    try{
        DbController db = new DbController();
        ResultSet rs = db.getReceiverName((String)request.getSession().getAttribute("username"));
        // ResultSet rs = db.getReceiverName("priyansh26");
        ArrayList<String> receiver = new ArrayList<>();
        while(rs.next()){
            System.out.println("user geted");
            receiver.add(rs.getString(1));
            receiver.add(rs.getString(2));
        }
        ArrayList<String> receivers = new ArrayList<>();
        for (String r : receiver){
            if(!receivers.contains(r)){
                receivers.add(r);
            }
        }

        Gson gson = new GsonBuilder().setPrettyPrinting().create();
        String json = gson.toJson(receivers);
        response.setContentType("application/json");
        response.getWriter().write(json);

    } catch(Exception e){
        System.out.println("Exception to get username " + e);
    }
}
}
