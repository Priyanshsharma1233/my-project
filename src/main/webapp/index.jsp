<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Login | MyChats</title>
  <link rel="stylesheet" href="styles/defaultlogin.css" />
</head>
<body>
  <main>
    <!-- Welcome Panel -->
    <section class="welcome-section">
      <h1>Welcome to MyChats</h1>
      <p>
        Connect instantly through seamless messaging. Real-time conversations,
        secure communication, and a friendly interface perfect for friends or professionals.
      </p>
    </section>

    <!-- Login Panel -->
    <section class="form-section">
      <h1>Login</h1>
      <form action="handleLogin" method="post" novalidate>
        <label for="username">Username</label>
        <input
          type="text"
          id="username"
          name="username"
          placeholder="Enter your username"
          required
          autocomplete="username"
        />

        <label for="password">Password</label>
        <input
          type="password"
          id="password"
          name="password"
          placeholder="Enter your password"
          required
          autocomplete="current-password"
        />

        <div id="messages" aria-live="polite" role="alert">
          <% if(request.getAttribute("errorMessage") != null) { %>
            <p class="error-message"><%= request.getAttribute("errorMessage") %></p>
          <% } %>
        </div>

        <div id="submit">
          <input type="submit" value="Login" />
        </div>
      </form>

      <p class="signup-link">No account? <a href="signup.jsp">Sign up here</a></p>
    </section>
  </main>
</body>
</html>
