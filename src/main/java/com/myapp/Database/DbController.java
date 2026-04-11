package com.myapp.Database;
import com.myapp.Message;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DbController {

    // ✅ Shared static connection — no new connection every request
    private static Connection sharedConnection = null;
    private static final Object LOCK = new Object();

    private static Connection getConnection() throws SQLException {
        synchronized (LOCK) {
            try {
                if (sharedConnection == null || sharedConnection.isClosed()) {
                    Class.forName("com.mysql.cj.jdbc.Driver");

                    String host     = getEnv("MYSQLHOST",     "localhost");
                    String port     = getEnv("MYSQLPORT",     "3306");
                    String user     = getEnv("MYSQLUSER",     "root");
                    String password = getEnv("MYSQLPASSWORD", "1234");
                    String database = getEnv("MYSQLDATABASE", "chatdb");

                    String url = "jdbc:mysql://" + host + ":" + port + "/" + database
                            + "?createDatabaseIfNotExist=true"
                            + "&useSSL=false"
                            + "&allowPublicKeyRetrieval=true"
                            + "&autoReconnect=true"
                            + "&characterEncoding=UTF-8";

                    sharedConnection = DriverManager.getConnection(url, user, password);
                    System.out.println("✅ DB connected");
                    createTables(sharedConnection);
                }
            } catch (ClassNotFoundException e) {
                throw new SQLException("Driver not found: " + e.getMessage());
            }
            return sharedConnection;
        }
    }

    private static void createTables(Connection conn) {
        try (Statement st = conn.createStatement()) {
            // ✅ password varchar(60) — supports BCrypt in future
            st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS users(" +
                            "name varchar(50), " +
                            "username varchar(20) PRIMARY KEY, " +
                            "password varchar(60))"
            );
            st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS Message(" +
                            "msgid int PRIMARY KEY AUTO_INCREMENT, " +
                            "sender varchar(20), " +
                            "receiver varchar(20), " +
                            "message varchar(1000), " +
                            "timestamps TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
            );
            st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS Recipient(" +
                            "id varchar(20) PRIMARY KEY, " +
                            "recipient varchar(20), " +
                            "user varchar(20))"
            );
            System.out.println("✅ Tables ready");
        } catch (SQLException e) {
            System.out.println("Table error: " + e.getMessage());
        }
    }

    private static String getEnv(String key, String fallback) {
        String value = System.getenv(key);
        return (value != null && !value.isEmpty()) ? value : fallback;
    }

    // ✅ Create user
    public int createUser(String name, String username, String password) {
        try {
            Connection conn = getConnection();
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO users(name,username,password) VALUES(?,?,?)")) {
                ps.setString(1, name);
                ps.setString(2, username);
                ps.setString(3, password);
                ps.executeUpdate();
                return 1;
            }
        } catch (SQLIntegrityConstraintViolationException e) {
            return 2;
        } catch (Exception e) {
            System.out.println("createUser error: " + e.getMessage());
            return 3;
        }
    }

    // ✅ Validate login
    public String validateUser(String username, String password) {
        if (username == null || password == null) return null;
        username = username.trim();
        password = password.trim();
        if (username.isEmpty() || password.isEmpty()) return null;

        try {
            Connection conn = getConnection();
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT name FROM users WHERE username=? AND password=?")) {
                ps.setString(1, username);
                ps.setString(2, password);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return rs.getString("name");
                }
            }
        } catch (Exception e) {
            System.out.println("validateUser error: " + e.getMessage());
        }
        return null;
    }

    // ✅ Get user by username
    public String getUsers(String username) {
        if (username == null) return null;
        try {
            Connection conn = getConnection();
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT username FROM users WHERE username=?")) {
                ps.setString(1, username.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return rs.getString("username");
                }
            }
        } catch (Exception e) {
            System.out.println("getUsers error: " + e.getMessage());
        }
        return null;
    }

    // ✅ Insert message
    public void insertMessage(Message message) throws SQLException {
        if (message == null || message.sender == null || message.receiver == null) return;
        Connection conn = getConnection();
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Message(sender,receiver,message) VALUES(?,?,?)")) {
            ps.setString(1, message.sender);
            ps.setString(2, message.receiver);
            ps.setString(3, message.message);
            ps.executeUpdate();
        }
    }

    // ✅ Get chat contacts
    public ResultSet getReceiverName(String username) throws SQLException {
        Connection conn = getConnection();
        PreparedStatement ps = conn.prepareStatement(
                "SELECT DISTINCT receiver, sender FROM Message WHERE sender=? OR receiver=?"
        );
        ps.setString(1, username);
        ps.setString(2, username);
        return ps.executeQuery();
    }

    // ✅ Get messages between two users
    public List<Message> getMessage(String sender, String receiver) throws SQLException {
        List<Message> list = new ArrayList<>();
        if (sender == null || receiver == null) return list;

        Connection conn = getConnection();
        String query =
                "SELECT * FROM message WHERE " +
                        "(sender=? AND receiver=?) OR (sender=? AND receiver=?) " +
                        "ORDER BY timestamps ASC";

        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, sender);
            ps.setString(2, receiver);
            ps.setString(3, receiver);
            ps.setString(4, sender);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Message msg = new Message();
                    msg.id        = rs.getInt("msgid");
                    msg.sender    = rs.getString("sender");
                    msg.receiver  = rs.getString("receiver");
                    msg.message   = rs.getString("message");
                    msg.timestamp = rs.getTimestamp("timestamps");
                    list.add(msg);
                }
            }
        }
        return list;
    }
}
