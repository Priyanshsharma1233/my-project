<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Create Account | MyChats</title>
  <link rel="stylesheet" href="styles/defaultsignup.css" />
</head>
<body>
  <main>
    <section class="welcome-section">
      <h1>Welcome to MyChats</h1>
      <p>
        My Chat is a dynamic chat website that lets users connect instantly through seamless messaging.
        With a user-friendly interface, real-time conversations, and secure communication,
        My Chat makes staying in touch easy, whether for casual chats or professional discussions.
      </p>
    </section>

    <section class="form-section">
      <h1>Create Account</h1>
      <form action="handleSignup" method="post" novalidate>
        <label for="name">Name</label>
        <input
          type="text"
          id="name"
          name="name"
          placeholder="Your full name"
          required
          autocomplete="name"
        />

        <label for="username">Username</label>
        <input
          type="text"
          id="username"
          name="username"
          placeholder="Choose a username"
          required
          autocomplete="username"
        />

        <label for="password">Password</label>
        <input
          type="password"
          id="password"
          name="password"
          placeholder="Create a password"
          required
          autocomplete="new-password"
        />

        <label for="rpassword">Confirm Password</label>
        <input
          type="password"
          id="rpassword"
          name="rpassword"
          placeholder="Re-enter your password"
          required
          autocomplete="new-password"
        />

        <div id="messages" aria-live="polite" role="alert">
          <% if(request.getAttribute("errorMessage") != null) { %>
            <p class="error-message"><%= request.getAttribute("errorMessage") %></p>
          <% } %>
        </div>

        <div id="submit">
          <input type="submit" value="Create Account" />
        </div>
      </form>
    </section>
  </main>
</body>
</html>
