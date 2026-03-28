<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home | MyChats</title>

    <!-- External Styles -->
    <link rel="stylesheet" href="styles/all.min.css">
   <link rel="stylesheet" href="<%= request.getContextPath() %>/styles/home.css?v=10">

    <!-- Icons -->
    <script src="scripts/all.min.js"></script>
</head>
<body>
    <main>
        <!-- Sidebar -->
        <section>
            <div class="btn top">
                <i class="fa-regular fa-message"></i>
                <i class="fa-regular fa-comment-dots"></i>

                <button type="button" id="showpopup">
                    <i class="fa-solid fa-plus"></i>
                </button>

                <div id="popup">
                    <div id="title-bar">
                        <span>Add Recipient</span>
                    </div>
                    <form onsubmit="return false;">
                        <input type="text" name="username" placeholder="username" class="abc">
                        <div id="userbutton"></div>
                        <button type="button" id="btnc">close</button>
                    </form>
                </div>
            </div>

            <div class="btn bottom">
                <a href="logout">
                    <i class="fa-solid fa-arrow-right-from-bracket"></i>
                </a>
            </div>
        </section>

        <!-- Chat List Section -->
        <section>
            <% if((String)request.getSession().getAttribute("username") != null){ %>
                <p id="welcome-text">Hello, <%= (String)request.getSession().getAttribute("name") %> 👋</p>
            <% } else {
                response.sendRedirect("index.jsp");
            } %>

            <label id="title">Chats</label>
            <input id="find" type="text" placeholder="Search..">
            <div id="RecpArea"></div>
        </section>

        <!-- Main Chat Area -->
        <section>
            <div id="main">
                <% if((String)request.getSession().getAttribute("receiver") == null){ %>
                    <p class="para">Select Recipient to start conversation</p>
                <% } %>

                <!-- ===== VIDEO CALL MODAL ===== -->
                <div id="videoModal" style="display:none; position:fixed; top:0; left:0; width:100%;
                     height:100%; background:rgba(0,0,0,0.85); z-index:1000; flex-direction:column;
                     align-items:center; justify-content:center;">

                    <div style="display:flex; gap:20px; margin-bottom:20px;">
                        <div style="text-align:center;">
                            <p style="color:white; margin-bottom:6px;">You</p>
                            <video id="localVideo" autoplay muted width="320" height="240"
                                   style="border-radius:12px; background:#111; display:block;"></video>
                        </div>
                        <div style="text-align:center;">
                            <p style="color:white; margin-bottom:6px;" id="remoteLabel">Waiting...</p>
                            <video id="remoteVideo" autoplay width="320" height="240"
                                   style="border-radius:12px; background:#111; display:block;"></video>
                        </div>
                    </div>

                    <button onclick="endCall()"
                        style="background:red; color:white; border:none; padding:10px 30px;
                               border-radius:25px; font-size:16px; cursor:pointer;">
                        🔴 End Call
                    </button>
                </div>
                <!-- ===== END VIDEO CALL MODAL ===== -->

                <div class="pro">
                    <div id="username">username</div>

                    <!-- Video Call Button -->
                    <button id="video-btn" title="Start Video Call" onclick="startVideoCall()"
                        style="background:none; border:none; font-size:20px; cursor:pointer; margin-left:auto;">
                        📹
                    </button>
                </div>

                <div id="chat-area"></div>

                <div class="pro">
                    <!-- Hidden file input -->
                    <input type="file" id="fileInput" style="display:none" />

                    <!-- File Share Button -->
                    <button id="file-btn" title="Send File"
                        onclick="document.getElementById('fileInput').click()"
                        style="background:none; border:none; font-size:20px; cursor:pointer;">
                        📎
                    </button>

                    <input type="text" name="message" placeholder="Message" id="msgText">

                    <button id="send-btn">
                        <img src="images/send.png" alt="Send" height="20" width="20">
                    </button>
                </div>
            </div>
        </section>
    </main>

    <script>
        // ========== Popup Controls ==========
        document.getElementById('showpopup').addEventListener('click', function () {
            document.getElementById('popup').style.transform = 'scale(1)';
        });

        document.getElementById('btnc').addEventListener('click', function () {
            document.getElementById('popup').style.transform = 'scale(0)';
        });

        // ========== Search User and Say Hi ==========
        document.querySelector('.abc').addEventListener('keyup', function () {
            const inputVal = this.value.trim();
            const userButton = document.getElementById('userbutton');

            if (inputVal === "") {
                userButton.innerHTML = '';
                return;
            }

            const url = "validateUser?username=" + encodeURIComponent(inputVal);

            fetch(url)
                .then(response => response.text())
                .then(data => {
                    const usernameFromDB = data.trim();
                    if (usernameFromDB && inputVal.toLowerCase() === usernameFromDB.toLowerCase()) {
                        userButton.innerHTML = `
                            <button type="button" onclick="sendMessage()">Say hi! to ${usernameFromDB}</button>`;
                    } else {
                        userButton.innerHTML = '';
                    }
                })
                .catch(error => console.error('Error:', error));
        });

        // Send "hi" message and auto-close popup
        function sendMessage() {
            const receiver = document.querySelector('.abc').value.trim();
            if (!receiver) return;

            const message = "hi";
            const xhr = new XMLHttpRequest();
            xhr.open("POST", "sendWelcomeMessage", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    alert("Message sent!");
                    document.getElementById('popup').style.transform = 'scale(0)';
                    document.querySelector('.abc').value = '';
                    document.getElementById('userbutton').innerHTML = '';
                }
            };
            xhr.send("receiver=" + encodeURIComponent(receiver) + "&message=" + encodeURIComponent(message));
        }

        // ========== Sending Messages ==========
        function MessageInChats() {
            const message = document.querySelector('#msgText').value.trim();
            if (message === "") return;

            const xhr = new XMLHttpRequest();
            xhr.open("POST", "sendMessage", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    document.querySelector('#msgText').value = '';
                }
            };
            xhr.send("message=" + encodeURIComponent(message));
        }

        document.getElementById("send-btn").addEventListener("click", MessageInChats);

        // Also send on Enter key
        document.getElementById("msgText").addEventListener("keydown", function (e) {
            if (e.key === "Enter") MessageInChats();
        });

        // ========== Load Receivers ==========
        function getReceiver() {
            const xhr = new XMLHttpRequest();
            xhr.open("POST", "getReceivers", true);
            xhr.onload = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const responseObject = JSON.parse(xhr.responseText);
                    const area = document.querySelector('#RecpArea');
                    area.innerHTML = '';

                    for (let ro of responseObject) {
                        const msg = `
                            <div id="Box">
                                <button class="name">
                                    <img src="images/usericon.png" width="25" height="25">${ro}
                                </button><hr>
                            </div>`;
                        area.innerHTML += msg;
                    }
                }
            };
            xhr.send();
        }
        getReceiver();

        // ========== Load Messages ==========
        function getMessages() {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "showChats", true);
            xhr.onload = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const messages = JSON.parse(xhr.responseText);
                    const area = document.getElementById('chat-area');
                    area.innerHTML = '';

                    for (const obj of messages) {
                        const isMe = obj['sender'] != document.getElementById('username').innerHTML;
                        const cssClass = isMe ? 'colorClass' : 'reciverChat';

                        // Check if message is a file
                        if (obj['message'].startsWith('__FILE__:')) {
                            const parts = obj['message'].replace('__FILE__:', '').split('::');
                            const fileUrl = parts[0];
                            const fileName = parts[1] || 'Download File';
                            area.innerHTML += `
                                <p class="${cssClass}">
                                    📎 <a href="${fileUrl}" download="${fileName}"
                                        style="color:inherit; text-decoration:underline;">${fileName}</a>
                                </p>`;
                        } else {
                            area.innerHTML += `
                                <p class="${cssClass}">${obj['message']}</p>`;
                        }
                    }
                }
            };
            xhr.send();
        }

        // ========== Select Recipient ==========
        window.addEventListener('click', async function (e) {
            if (e.target.className === 'name') {
                const receiver = e.target.textContent.trim();
                const url = `setReceive?receiver=${receiver}`;
                const response = await fetch(url);

                if (response.ok) {
                    const pros = document.getElementsByClassName('pro');
                    for (let i = 0; i < pros.length; i++) pros[i].style.display = 'block';

                    try {
                        document.querySelector('.para').style.display = 'none';
                    } catch (e) {}

                    document.getElementById('username').innerHTML = receiver;
                    setInterval(getMessages, 1000);
                }
            }
        });

        // Auto scroll chat to bottom
        function scrollDivToBottom() {
            try {
                const div = document.getElementById("chat-area");
                div.scrollTop = div.scrollHeight;
            } catch (e) {}
        }
        setInterval(scrollDivToBottom, 1000);

        // ========== File Sharing ==========
        document.getElementById('fileInput').addEventListener('change', async function () {
            const file = this.files[0];
            if (!file) return;

            if (file.size > 50 * 1024 * 1024) {
                alert("File too large! Max allowed size is 50MB.");
                return;
            }

            const formData = new FormData();
            formData.append("file", file);

            try {
                const res = await fetch("upload", { method: "POST", body: formData });
                const data = await res.json();

                if (data.error) { alert(data.error); return; }

                // Send file as a special chat message
                const xhr = new XMLHttpRequest();
                xhr.open("POST", "sendMessage", true);
                xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                xhr.send("message=" + encodeURIComponent("__FILE__:" + data.url + "::" + data.name));

                // Reset file input
                document.getElementById('fileInput').value = '';

            } catch (err) {
                alert("File upload failed. Please try again.");
                console.error(err);
            }
        });

        // ========== Video Call (WebRTC) ==========
        const rtcConfig = { iceServers: [{ urls: "stun:stun.l.google.com:19302" }] };
        let peerConnection = null;
        let localStream = null;
        let signalSocket = null;

        function startVideoCall() {
            const receiver = document.getElementById('username').innerHTML.trim();
            if (!receiver || receiver === 'username') {
                alert("Please select a recipient first.");
                return;
            }

            document.getElementById('videoModal').style.display = 'flex';
            document.getElementById('remoteLabel').innerText = receiver;

            // Create consistent room ID by sorting usernames alphabetically
            const me = '<%= session.getAttribute("username") %>';
            const roomId = [me, receiver].sort().join('_');
            initWebRTC(roomId, true);
        }

        async function initWebRTC(roomId, isInitiator) {
            const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
            signalSocket = new WebSocket(`${wsProtocol}://${window.location.host}/signal/${roomId}`);

            peerConnection = new RTCPeerConnection(rtcConfig);

            // Get local camera and microphone
            try {
                localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
                document.getElementById('localVideo').srcObject = localStream;
                localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));
            } catch (err) {
                alert("Could not access camera/microphone. Please check permissions.");
                endCall();
                return;
            }

            // Send ICE candidates to peer via signaling server
            peerConnection.onicecandidate = (e) => {
                if (e.candidate && signalSocket.readyState === WebSocket.OPEN) {
                    signalSocket.send(JSON.stringify({ type: 'ice-candidate', data: e.candidate }));
                }
            };

            // Show remote video stream when it arrives
            peerConnection.ontrack = (e) => {
                document.getElementById('remoteVideo').srcObject = e.streams[0];
            };

            // Handle signals from the other peer
            signalSocket.onmessage = async (event) => {
                const signal = JSON.parse(event.data);

                if (signal.type === 'offer') {
                    await peerConnection.setRemoteDescription(new RTCSessionDescription(signal.data));
                    const answer = await peerConnection.createAnswer();
                    await peerConnection.setLocalDescription(answer);
                    signalSocket.send(JSON.stringify({ type: 'answer', data: answer }));

                } else if (signal.type === 'answer') {
                    await peerConnection.setRemoteDescription(new RTCSessionDescription(signal.data));

                } else if (signal.type === 'ice-candidate') {
                    try {
                        await peerConnection.addIceCandidate(new RTCIceCandidate(signal.data));
                    } catch (e) {
                        console.error("ICE candidate error:", e);
                    }
                }
            };

            // If initiator, create and send offer after socket opens
            if (isInitiator) {
                signalSocket.onopen = async () => {
                    const offer = await peerConnection.createOffer();
                    await peerConnection.setLocalDescription(offer);
                    signalSocket.send(JSON.stringify({ type: 'offer', data: offer }));
                };
            }
        }

        function endCall() {
            if (peerConnection) { peerConnection.close(); peerConnection = null; }
            if (localStream) { localStream.getTracks().forEach(t => t.stop()); localStream = null; }
            if (signalSocket) { signalSocket.close(); signalSocket = null; }
            document.getElementById('localVideo').srcObject = null;
            document.getElementById('remoteVideo').srcObject = null;
            document.getElementById('videoModal').style.display = 'none';
        }
    </script>
</body>
</html>