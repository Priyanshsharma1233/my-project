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
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
            } catch (ClassNotFoundException e) {
                System.out.println("Driver not found");
            }

            // ✅ Read from environment variables (Railway)
            // Falls back to localhost for local development
            String host     = getEnv("MYSQLHOST",     "localhost");
            String port     = getEnv("MYSQLPORT",     "3306");
            String user     = getEnv("MYSQLUSER",     "root");
            String password = getEnv("MYSQLPASSWORD", "1234");
            String database = getEnv("MYSQLDATABASE", "chatdb");

            String url = "jdbc:mysql://" + host + ":" + port + "/" + database
                    + "?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true";

            connection = DriverManager.getConnection(url, user, password);
            Statement statement = connection.createStatement();

            try {
                statement.executeUpdate("create table if not exists users(name varchar(20), username varchar(20) primary key, password varchar(10))");
            } catch (SQLException e) {
                System.out.println("error in create users table " + e);
            }

            try {
                statement.executeUpdate("create table if not exists Message(msgid int primary key auto_increment, sender varchar(20), Receiver varchar(20), message varchar(500), timestamps timestamp default current_timestamp)");
            } catch (SQLException e) {
                System.out.println("error in create Message table " + e);
            }

            try {
                statement.executeUpdate("create table if not exists Recipient(id varchar(20) primary key, recipient varchar(20), user varchar(20))");
            } catch (SQLException e) {
                System.out.println("error in create Recipient table " + e);
            }

        } catch (Exception e) {
            System.out.println("error in connecting " + e);
        }
    }

    // ✅ Helper to read environment variable with fallback
    private String getEnv(String key, String fallback) {
        String value = System.getenv(key);
        return (value != null && !value.isEmpty()) ? value : fallback;
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
            return 2;
        } catch (Exception e) {
            System.out.println("Something went wrong " + e);
            return 3;
        }
    }

    public String validateUser(String username, String password) {
        if (username == null || password == null) return null;
        username = username.trim();
        password = password.trim();
        if (username.isEmpty() || password.isEmpty()) return null;

        try {
            if (connection == null || connection.isClosed()) {
                System.out.println("validateUser: DB connection is null or closed!");
                return null;
            }
        } catch (Exception e) {
            System.out.println("validateUser: error checking connection: " + e);
            return null;
        }

        String sql = "SELECT name FROM users WHERE username = ? AND password = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("name");
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
            ps.setString(1, username);
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

    public void insertMessage(Message message) throws SQLException {
        PreparedStatement statement = connection.prepareStatement("insert into Message(sender,receiver,message) value(?,?,?)");
        statement.setString(1, message.sender);
        statement.setString(2, message.receiver);
        statement.setString(3, message.message);
        statement.executeUpdate();
    }

    public ResultSet getReceiverName(String username) throws SQLException {
        PreparedStatement statement = connection.prepareStatement("select distinct receiver, sender from Message where sender=? or receiver=?");
        statement.setString(1, username);
        statement.setString(2, username);
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
                    Messages.add(message);
                }
            }
        }
        return Messages;
    }
}