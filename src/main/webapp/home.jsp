<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home | MyChats</title>

    <!-- Font Awesome -->
    <link rel="stylesheet" href="styles/all.min.css">

    <!-- App Styles -->
    <link rel="stylesheet" href="styles/home.css?v=16">
</head>
<body>
<main>

    <!-- SIDEBAR -->
    <section class="sidebar">
        <div class="btn top">
            <button><i class="fa-regular fa-message"></i></button>
            <button><i class="fa-regular fa-comment-dots"></i></button>
            <button type="button" id="showpopup">
                <i class="fa-solid fa-plus"></i>
            </button>
        </div>
        <div class="btn bottom">
            <a href="logout">
                <i class="fa-solid fa-arrow-right-from-bracket"></i>
            </a>
        </div>
    </section>

    <!-- POPUP -->
    <div id="popup">
        <div id="title-bar">
            <span>Add Recipient</span>
        </div>
        <form onsubmit="return false;">
            <input type="text" name="username" placeholder="Search username..." class="abc" autocomplete="off">
            <div id="userbutton"></div>
            <button type="button" id="btnc">Close</button>
        </form>
    </div>

    <!-- Chat List -->
    <section>
        <% if((String)request.getSession().getAttribute("username") != null){ %>
            <p id="welcome-text">Hello, <%= (String)request.getSession().getAttribute("name") %> 👋</p>
        <% } else {
            response.sendRedirect("index.jsp");
        } %>
        <label id="title">Chats</label>
        <input id="find" type="text" placeholder="Search chats..." autocomplete="off">
        <div id="RecpArea"></div>
    </section>

    <!-- Chat Area -->
    <section>
        <div id="main">

            <% if((String)request.getSession().getAttribute("receiver") == null){ %>
                <p class="para">Select Recipient to start conversation</p>
            <% } %>

            <!-- VIDEO CALL MODAL -->
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

            <!-- HEADER with online status -->
            <div class="pro">
                <div style="display:flex; flex-direction:column;">
                    <div id="username">username</div>
                    <span id="header-status"></span>
                </div>
                <button id="video-btn" onclick="startVideoCall()" style="margin-left:auto;">📹</button>
            </div>

            <!-- TYPING INDICATOR -->
            <div id="typing-indicator">typing...</div>

            <!-- CHAT -->
            <div id="chat-area"></div>

            <!-- INPUT -->
            <div class="pro">
                <input type="file" id="fileInput" style="display:none" />
                <button id="file-btn" onclick="document.getElementById('fileInput').click()">📎</button>
                <input type="text" id="msgText" placeholder="Message">
                <button id="send-btn">➤</button>
            </div>

        </div>
    </section>

</main>

<script>

    const ME = '<%= session.getAttribute("username") %>';

    // ========== POPUP CONTROLS ==========
    const popup = document.getElementById('popup');

    document.getElementById('showpopup').onclick = (e) => {
        e.stopPropagation();
        popup.classList.add('active');
        document.querySelector('.abc').value = '';
        document.getElementById('userbutton').innerHTML = '';
    };

    document.getElementById('btnc').onclick = () => {
        popup.classList.remove('active');
    };

    document.addEventListener('click', function(e) {
        if (!popup.contains(e.target) && e.target.id !== 'showpopup') {
            popup.classList.remove('active');
        }
    });

    // ========== SEARCH USER IN POPUP ==========
    document.querySelector('.abc').addEventListener('keyup', function () {
        const inputVal = this.value.trim();
        const userButton = document.getElementById('userbutton');

        if (inputVal === "") {
            userButton.innerHTML = '';
            return;
        }

        fetch("validateUser?username=" + encodeURIComponent(inputVal))
            .then(response => response.text())
            .then(data => {
                const usernameFromDB = data.trim();
                if (usernameFromDB && inputVal.toLowerCase() === usernameFromDB.toLowerCase()) {
                    userButton.innerHTML = `
                        <button type="button" onclick="sayHi('${usernameFromDB}')">
                            👋 Say hi! to ${usernameFromDB}
                        </button>`;
                } else {
                    userButton.innerHTML = '<p style="color:#94a3b8; font-size:13px; margin-top:8px;">User not found</p>';
                }
            })
            .catch(error => {
                console.error('Error:', error);
                userButton.innerHTML = '';
            });
    });

    // ========== SAY HI ==========
    function sayHi(receiver) {
        if (!receiver) return;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", "sendWelcomeMessage", true);
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    alert("👋 Message sent to " + receiver + "!");
                    popup.classList.remove('active');
                    document.querySelector('.abc').value = '';
                    document.getElementById('userbutton').innerHTML = '';
                    getReceiver();
                } else {
                    alert("Failed to send message. Please try again.");
                }
            }
        };

        xhr.send("receiver=" + encodeURIComponent(receiver) + "&message=hi");
    }

    // ========== SEND MESSAGE ==========
    function MessageInChats() {
        const message = document.querySelector('#msgText').value.trim();
        if (message === "") return;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", "sendMessage", true);
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                document.querySelector('#msgText').value = '';
                // ✅ Stop typing indicator when message sent
                sendTypingStatus(false);
            }
        };

        xhr.send("message=" + encodeURIComponent(message));
    }

    document.getElementById("send-btn").addEventListener("click", MessageInChats);
    document.getElementById("msgText").addEventListener("keydown", function (e) {
        if (e.key === "Enter") MessageInChats();
    });

    // ========== LOAD RECEIVERS ==========
    function getReceiver() {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "getReceivers", true);

        xhr.onload = function () {
            if (xhr.status === 200) {
                if (!xhr.responseText || xhr.responseText.trim() === '') return;
                let responseObject;
                try {
                    responseObject = JSON.parse(xhr.responseText);
                } catch (e) {
                    console.log("getReceiver JSON error:", xhr.responseText);
                    return;
                }

                const area = document.querySelector('#RecpArea');
                area.innerHTML = '';

                for (let ro of responseObject) {
                    // ✅ Add online status dot
                    area.innerHTML += `
                        <div class="chatBox" id="chatBox_${ro}">
                            <button class="name">
                                <span class="user-status" id="status_${ro}"></span>
                                <img src="images/usericon.png" width="25" height="25"
                                     onerror="this.style.display='none'">${ro}
                            </button>
                        </div>`;
                }

                // ✅ Check online status for all users
                responseObject.forEach(user => checkOnlineStatus(user));
            }
        };
        xhr.send();
    }
    getReceiver();

    // ========== SEARCH EXISTING CHATS ==========
    document.getElementById('find').addEventListener('keyup', function () {
        const searchVal = this.value.trim().toLowerCase();
        const allBoxes = document.querySelectorAll('#RecpArea .chatBox');

        allBoxes.forEach(box => {
            const nameBtn = box.querySelector('.name');
            if (nameBtn) {
                const name = nameBtn.textContent.trim().toLowerCase();
                box.style.display = name.includes(searchVal) ? 'block' : 'none';
            }
        });
    });

    // ========== LOAD MESSAGES ==========
    function getMessages() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "showChats", true);

        xhr.onload = function () {
            if (xhr.status === 200) {
                if (!xhr.responseText || xhr.responseText.trim() === '') return;
                let messages;
                try {
                    messages = JSON.parse(xhr.responseText);
                } catch (e) {
                    console.log("getMessages JSON error:", xhr.responseText);
                    return;
                }

                const area = document.getElementById('chat-area');
                area.innerHTML = '';

                for (const obj of messages) {
                    const isMe = obj['sender'] != document.getElementById('username').innerHTML;
                    const cssClass = isMe ? 'colorClass' : 'receiverChat';

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
                        area.innerHTML += `<p class="${cssClass}">${obj['message']}</p>`;
                    }
                }
            }
        };
        xhr.send();
    }

    // ========== SELECT USER ==========
    window.addEventListener('click', async function (e) {
        const nameBtn = e.target.closest('.name');
        if (nameBtn) {
            const receiver = nameBtn.textContent.trim();
            if (!receiver) return;

            const response = await fetch(`setReceive?receiver=${encodeURIComponent(receiver)}`);
            if (response.ok) {
                document.getElementById('username').innerHTML = receiver;

                const pros = document.getElementsByClassName('pro');
                for (let i = 0; i < pros.length; i++) pros[i].style.display = 'flex';

                try { document.querySelector('.para').style.display = 'none'; } catch(e) {}

                // ✅ Update header online status
                updateHeaderStatus(receiver);

                setInterval(getMessages, 1000);
            }
        }
    });

    // Auto scroll to bottom
    setInterval(() => {
        try {
            const div = document.getElementById("chat-area");
            div.scrollTop = div.scrollHeight;
        } catch (e) {}
    }, 1000);

    // ========== FILE SHARING ==========
    document.getElementById('fileInput').addEventListener('change', async function () {
        const file = this.files[0];
        if (!file) return;

        if (file.size > 50 * 1024 * 1024) {
            alert("File too large! Max 50MB.");
            return;
        }

        const formData = new FormData();
        formData.append("file", file);

        try {
            const res = await fetch("upload", { method: "POST", body: formData });
            const data = await res.json();

            if (data.error) { alert(data.error); return; }

            const xhr = new XMLHttpRequest();
            xhr.open("POST", "sendMessage", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            xhr.send("message=" + encodeURIComponent("__FILE__:" + data.url + "::" + data.name));

            document.getElementById('fileInput').value = '';

        } catch (err) {
            alert("File upload failed.");
            console.error(err);
        }
    });

    // ========== RESTORE SELECTED RECIPIENT ON REFRESH ==========
    window.addEventListener('load', async function () {
        const savedReceiver = '<%= session.getAttribute("receiver") != null ? session.getAttribute("receiver") : "" %>';

        if (savedReceiver && savedReceiver !== '') {
            // ✅ Set the username in header
            document.getElementById('username').innerHTML = savedReceiver;

            // ✅ Show the chat input and header
            const pros = document.getElementsByClassName('pro');
            for (let i = 0; i < pros.length; i++) pros[i].style.display = 'flex';

            // ✅ Hide the "select recipient" message
            try { document.querySelector('.para').style.display = 'none'; } catch(e) {}

            // ✅ Update online status in header
            updateHeaderStatus(savedReceiver);

            // ✅ Start loading messages
            setInterval(getMessages, 1000);

            // ✅ Highlight the selected user in chat list
            // Wait for chat list to load then highlight
            setTimeout(() => {
                const allNames = document.querySelectorAll('.name');
                allNames.forEach(btn => {
                    if (btn.textContent.trim() === savedReceiver) {
                        btn.style.background = '#d9fdd3';
                    }
                });
            }, 500);
        }
    });

    // ========== ONLINE & TYPING (Presence WebSocket) ==========
    let presenceSocket = null;
    let typingTimer = null;
    let onlineStatusMap = {}; // username -> true/false

    function connectPresence() {
        if (!ME || ME === 'null') return;

        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
        presenceSocket = new WebSocket(
            `${wsProtocol}://${window.location.host}/presence/${ME}`
        );

        presenceSocket.onopen = () => {
            console.log("✅ Presence connected");
        };

        presenceSocket.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                const currentReceiver = document.getElementById('username').innerHTML.trim();

                if (data.type === 'online') {
                    // ✅ Mark user as online in chat list
                    onlineStatusMap[data.user] = true;
                    updateStatusDot(data.user, true);
                    if (data.user === currentReceiver) updateHeaderStatus(currentReceiver);

                } else if (data.type === 'offline') {
                    // ✅ Mark user as offline
                    onlineStatusMap[data.user] = false;
                    updateStatusDot(data.user, false);
                    if (data.user === currentReceiver) updateHeaderStatus(currentReceiver);

                } else if (data.type === 'typing') {
                    // ✅ Show typing indicator
                    if (data.from === currentReceiver) {
                        showTypingIndicator(data.isTyping);
                    }
                }
            } catch (e) {
                console.error("Presence message error:", e);
            }
        };

        presenceSocket.onclose = () => {
            console.log("Presence disconnected, reconnecting in 3s...");
            setTimeout(connectPresence, 3000);
        };

        presenceSocket.onerror = (e) => {
            console.error("Presence error:", e);
        };
    }

    // ✅ Connect presence when page loads
    connectPresence();

    // ✅ Check if a specific user is online
    function checkOnlineStatus(username) {
        const dot = document.getElementById('status_' + username);
        if (dot) {
            dot.classList.toggle('online', onlineStatusMap[username] === true);
        }
    }

    // ✅ Update status dot in chat list
    function updateStatusDot(username, isOnline) {
        const dot = document.getElementById('status_' + username);
        if (dot) {
            if (isOnline) {
                dot.classList.add('online');
            } else {
                dot.classList.remove('online');
            }
        }
    }

    // ✅ Update header status text
    function updateHeaderStatus(username) {
        const statusEl = document.getElementById('header-status');
        if (onlineStatusMap[username]) {
            statusEl.textContent = '🟢 Online';
            statusEl.style.color = '#25d366';
        } else {
            statusEl.textContent = '⚫ Offline';
            statusEl.style.color = '#999';
        }
    }

    // ✅ Show/hide typing indicator
    function showTypingIndicator(isTyping) {
        const indicator = document.getElementById('typing-indicator');
        const receiver = document.getElementById('username').innerHTML.trim();
        if (isTyping) {
            indicator.textContent = receiver + ' is typing...';
            indicator.classList.add('visible');
        } else {
            indicator.classList.remove('visible');
        }
    }

    // ✅ Send typing status to receiver
    function sendTypingStatus(isTyping) {
        const receiver = document.getElementById('username').innerHTML.trim();
        if (!receiver || receiver === 'username') return;
        if (!presenceSocket || presenceSocket.readyState !== WebSocket.OPEN) return;

        presenceSocket.send(JSON.stringify({
            type: 'typing',
            to: receiver,
            from: ME,
            isTyping: isTyping
        }));
    }

    // ✅ Detect typing in message box
    document.getElementById('msgText').addEventListener('input', function () {
        sendTypingStatus(true);

        // Stop typing after 2 seconds of no input
        clearTimeout(typingTimer);
        typingTimer = setTimeout(() => {
            sendTypingStatus(false);
        }, 2000);
    });

    // ========== VIDEO CALL ==========
    const rtcConfig = {
        iceServers: [
            { urls: "stun:stun.l.google.com:19302" },
            { urls: "stun:stun1.l.google.com:19302" }
        ]
    };
    let peerConnection = null;
    let localStream = null;
    let signalSocket = null;
    let incomingSignalSocket = null;

    function connectIncomingSignal() {
        if (!ME || ME === 'null') return;

        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';

        incomingSignalSocket = new WebSocket(
            `${wsProtocol}://${window.location.host}/signal/incoming_${ME}`
        );

        incomingSignalSocket.onopen = () => {
            console.log("✅ Waiting for incoming calls as: " + ME);
        };

        incomingSignalSocket.onmessage = async (event) => {
            const signal = JSON.parse(event.data);

            if (signal.type === 'call-request') {
                const caller = signal.caller;
                const accept = confirm(`📹 Incoming video call from ${caller}. Accept?`);

                if (accept) {
                    document.getElementById('videoModal').style.display = 'flex';
                    document.getElementById('remoteLabel').innerText = caller;
                    const roomId = [ME, caller].sort().join('_');
                    initWebRTC(roomId, false);
                }
            }
        };

        incomingSignalSocket.onclose = () => {
            setTimeout(connectIncomingSignal, 3000);
        };

        incomingSignalSocket.onerror = (e) => {
            console.error("Incoming signal error:", e);
        };
    }

    connectIncomingSignal();

    function startVideoCall() {
        const receiver = document.getElementById('username').innerHTML.trim();
        if (!receiver || receiver === 'username') {
            alert("Please select a recipient first.");
            return;
        }

        document.getElementById('videoModal').style.display = 'flex';
        document.getElementById('remoteLabel').innerText = receiver;

        const roomId = [ME, receiver].sort().join('_');
        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';

        const notifySocket = new WebSocket(
            `${wsProtocol}://${window.location.host}/signal/incoming_${receiver}`
        );

        notifySocket.onopen = () => {
            notifySocket.send(JSON.stringify({ type: 'call-request', caller: ME }));
            setTimeout(() => notifySocket.close(), 1000);
        };

        initWebRTC(roomId, true);
    }

    async function initWebRTC(roomId, isInitiator) {
        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';

        peerConnection = new RTCPeerConnection(rtcConfig);

        try {
            localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
            document.getElementById('localVideo').srcObject = localStream;
            localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));
        } catch (err) {
            alert("Could not access camera/microphone. Please allow permission and try again.");
            endCall();
            return;
        }

        signalSocket = new WebSocket(
            `${wsProtocol}://${window.location.host}/signal/${roomId}`
        );

        peerConnection.onicecandidate = (e) => {
            if (e.candidate && signalSocket.readyState === WebSocket.OPEN) {
                signalSocket.send(JSON.stringify({ type: 'ice-candidate', data: e.candidate }));
            }
        };

        peerConnection.ontrack = (e) => {
            document.getElementById('remoteVideo').srcObject = e.streams[0];
        };

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
                } catch (e) { console.error("ICE error:", e); }
            }
        };

        signalSocket.onerror = (e) => console.error("Signal error:", e);
        signalSocket.onclose = () => console.log("Signal closed");

        if (isInitiator) {
            signalSocket.onopen = async () => {
                const offer = await peerConnection.createOffer();
                await peerConnection.setLocalDescription(offer);
                signalSocket.send(JSON.stringify({ type: 'offer', data: offer }));
            };
        } else {
            signalSocket.onopen = () => {
                console.log("✅ Receiver ready...");
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