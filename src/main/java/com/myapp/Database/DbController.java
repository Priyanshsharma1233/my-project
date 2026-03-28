package com.myapp.Database;
import com.myapp.Message;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DbController {
    Connection connection;
    PreparedStatement pstmt;

    public DbController() {
        try {
            try{
                Class.forName("com.mysql.jdbc.Driver");
            } catch(ClassNotFoundException e){
                System.out.println("Driver not found");
            }
            connection = DriverManager.getConnection("jdbc:mysql://localhost", "root", "1234");
            Statement statement = connection.createStatement();
            try {
                statement.executeUpdate("create database chatdb");
                statement.executeUpdate("use chatdb");
            } catch (SQLException ex) {
                if (ex.getErrorCode() == 1007) {
                    statement.executeUpdate("use chatdb");
                }
            }
            try {
                statement.executeUpdate("create table users(name varchar(20),username varchar(20) primary key,password varchar(10))");
            } catch (SQLException e) {
                if (e.getErrorCode() == 1050) {
                    System.out.println("error in create table");
                }
            }
          // first table
            try {
                statement.executeUpdate("create table Message(msgid int primary key auto_increment,sender varchar(20),Receiver varchar(20), message varchar(500),timestamps timestamp default current_timestamp)");
            } catch (SQLException e) {
                if (e.getErrorCode() == 1050) {
                    System.out.println("error in create Message table "+ e);
                }

            }
//           second table
            try {
                statement.executeUpdate("create table Recipient(id varchar(20) primary key,recipient varchar(20),user varchar(20))");
            } catch (SQLException e) {
                if (e.getErrorCode() == 1050) {
                    System.out.println("error in create Recipient table");
                }
            }

        } catch (Exception e) {
            System.out.println("error in connecting " + e);
        }
    }

    public int createUser(String name, String username, String password) {
        try {
            pstmt = connection.prepareStatement("insert into users (name, username, password) values (?,?,?)");
            pstmt.setString(1, name);
            pstmt.setString(2, username);
            pstmt.setString(3, password);
            pstmt.executeUpdate();
            return 1;
        } catch (SQLIntegrityConstraintViolationException e) {
            //System.out.println("Error to create User" +e);
            return 2;
        }
        catch (Exception e) {
            System.out.println("Something want wrong " + e);
            return 3;
        }
    }

    public String validateUser(String username, String password) {
        // 1) quick input guard
        if (username == null || password == null) return null;
        username = username.trim();
        password = password.trim();
        if (username.isEmpty() || password.isEmpty()) return null;

        // 2) defensive check that connection exists
        try {
            if (connection == null || connection.isClosed()) {
                System.out.println("validateUser: DB connection is null or closed!");
                return null;
            }
        } catch (Exception e) {
            System.out.println("validateUser: error checking connection: " + e);
            return null;
        }

        // 3) query using try-with-resources to avoid leaks and to log problems
        String sql = "SELECT name FROM users WHERE username = ? AND password = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);

            System.out.println("validateUser: executing query for username='" + username + "'");

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String name = rs.getString("name");
                    System.out.println("validateUser: user found, name=" + name);
                    return name;
                } else {
                    System.out.println("validateUser: no matching user found for username='" + username + "'");
                }
            }
        } catch (SQLException sq) {
            System.out.println("validateUser: SQL error: " + sq.getMessage());
        } catch (Exception ex) {
            System.out.println("validateUser: unexpected error: " + ex);
        }

        return null;
    }

    public String getUsers(String username) {
        String user = null;
        try {
            String query = "SELECT username FROM users WHERE username = ?";
            PreparedStatement ps = connection.prepareStatement(query);
            ps.setString(1, username); // exact match, not partial
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                user = rs.getString("username");
            }
            rs.close();
            ps.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return user;
    }


    public void insertMessage(Message message)throws SQLException {
        PreparedStatement statement = connection.prepareStatement("insert into Message(sender,receiver,message) value(?,?,?)");
        statement.setString(1, message.sender);
        statement.setString(2, message.receiver);
        statement.setString(3, message.message);
        statement.executeUpdate();
    }

    public ResultSet getReceiverName(String username)throws SQLException{
        PreparedStatement statement = connection.prepareStatement("select distinct receiver, sender from Message where sender=? or receiver=?");
        statement.setString(1,username);
        statement.setString(2,username);
        return statement.executeQuery();
    }

    public List<Message> getMessage(String sender, String receiver) throws SQLException {
        List<Message> Messages = new ArrayList<>();
        String query = "SELECT * FROM message WHERE (sender = ? AND receiver = ?) OR (sender = ? AND receiver = ?) ORDER BY timestamps ASC";

        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setString(1, sender);
            statement.setString(2, receiver);
            statement.setString(3, receiver);
            statement.setString(4, sender);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Message message = new Message();
                    message.id = resultSet.getInt("msgid");
                    message.sender = resultSet.getString("sender");
                    message.receiver = resultSet.getString("receiver");
                    message.message = resultSet.getString("message");
                    message.timestamp = resultSet.getTimestamp("timestamps");

                    Messages.add(message);  // Add each message to the list
                }
            }
        }


        return Messages;
    }

}