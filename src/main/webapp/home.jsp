<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">

       <head>
           <meta charset="UTF-8">
           <meta name="viewport" content="width=device-width, initial-scale=1.0">
           <title>Home | MyChats</title>

           <!-- ✅ Local Font Awesome -->
           <link rel="stylesheet" href="styles/all.min.css">

           <!-- ✅ Your CSS -->
           <link rel="stylesheet" href="styles/home.css?v=15">
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

            <!-- HEADER -->
            <div class="pro">
                <div id="username">username</div>
                <button id="video-btn" onclick="startVideoCall()" style="margin-left:auto;">📹</button>
            </div>

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

                // ✅ Safe JSON parse
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
                    area.innerHTML += `
                        <div class="chatBox">
                            <button class="name">
                                <img src="images/usericon.png" width="25" height="25"
                                     onerror="this.style.display='none'">${ro}
                            </button>
                        </div>`;
                }
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
                if (name.includes(searchVal)) {
                    box.style.display = 'block';
                } else {
                    box.style.display = 'none';
                }
            }
        });
    });

    // ========== LOAD MESSAGES ==========
    function getMessages() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "showChats", true);

        xhr.onload = function () {
            if (xhr.status === 200) {

                // ✅ Safe JSON parse — fixes blank screen error
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
        const me = '<%= session.getAttribute("username") %>';
        if (!me || me === 'null') return;

        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';

        incomingSignalSocket = new WebSocket(
            `${wsProtocol}://${window.location.host}/signal/incoming_${me}`
        );

        incomingSignalSocket.onopen = () => {
            console.log("✅ Waiting for incoming calls as: " + me);
        };

        incomingSignalSocket.onmessage = async (event) => {
            const signal = JSON.parse(event.data);

            if (signal.type === 'call-request') {
                const caller = signal.caller;
                const accept = confirm(`📹 Incoming video call from ${caller}. Accept?`);

                if (accept) {
                    document.getElementById('videoModal').style.display = 'flex';
                    document.getElementById('remoteLabel').innerText = caller;

                    const me = '<%= session.getAttribute("username") %>';
                    const roomId = [me, caller].sort().join('_');
                    initWebRTC(roomId, false);
                }
            }
        };

        incomingSignalSocket.onclose = () => {
            console.log("Disconnected, reconnecting in 3s...");
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

        const me = '<%= session.getAttribute("username") %>';
        const roomId = [me, receiver].sort().join('_');
        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';

        const notifySocket = new WebSocket(
            `${wsProtocol}://${window.location.host}/signal/incoming_${receiver}`
        );

        notifySocket.onopen = () => {
            notifySocket.send(JSON.stringify({
                type: 'call-request',
                caller: me
            }));
            console.log("✅ Call request sent to: " + receiver);
            setTimeout(() => notifySocket.close(), 1000);
        };

        notifySocket.onerror = (e) => {
            console.error("Notify error:", e);
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
            console.log("✅ Remote stream received");
            document.getElementById('remoteVideo').srcObject = e.streams[0];
        };

        signalSocket.onmessage = async (event) => {
            const signal = JSON.parse(event.data);
            console.log("Signal received:", signal.type);

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
                console.log("✅ Initiator: sending offer...");
                const offer = await peerConnection.createOffer();
                await peerConnection.setLocalDescription(offer);
                signalSocket.send(JSON.stringify({ type: 'offer', data: offer }));
            };
        } else {
            signalSocket.onopen = () => {
                console.log("✅ Receiver: ready, waiting for offer...");
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
