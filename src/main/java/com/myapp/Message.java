package com.myapp;

import java.sql.Timestamp;

public class Message {
    public int id;
    public String sender;
    public String receiver;
    public String message;
    public Timestamp timestamp;

    public Message(){

    }

    public Message(String sender, String receiver, String message){
        this.sender = sender;
        this.receiver = receiver;
        this.message = message;
    }
}
