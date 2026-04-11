<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String sessionUsername = (String) request.getSession().getAttribute("username");
    String sessionName     = (String) request.getSession().getAttribute("name");
    String sessionReceiver = (String) request.getSession().getAttribute("receiver");
    if (sessionUsername == null) { response.sendRedirect("index.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home | MyChats</title>
    <link rel="stylesheet" href="styles/all.min.css">
    <link rel="stylesheet" href="styles/home.css?v=18">
    <style>
        .user-status { width:10px; height:10px; border-radius:50%; background:#ccc; display:inline-block; flex-shrink:0; }
        .user-status.online { background:#25d366; }
        #typing-indicator { font-size:12px; color:#25d366; padding:4px 15px; min-height:22px; font-style:italic; }
        #header-status { font-size:12px; color:#999; }
        .chatBox { position:relative; }
    </style>
</head>
<body>
<main>

    <section class="sidebar">
        <div class="btn top">
            <button title="Chats"><i class="fa-regular fa-message"></i></button>
            <button title="Contacts"><i class="fa-regular fa-comment-dots"></i></button>
            <button type="button" id="showpopup" title="Add"><i class="fa-solid fa-plus"></i></button>
        </div>
        <div class="btn bottom">
            <a href="logout" title="Logout"><i class="fa-solid fa-arrow-right-from-bracket"></i></a>
        </div>
    </section>

    <div id="popup">
        <div id="title-bar"><span>Add Recipient</span></div>
        <form onsubmit="return false;">
            <input type="text" name="username" placeholder="Search username..." class="abc" autocomplete="off">
            <div id="userbutton"></div>
            <button type="button" id="btnc">Close</button>
        </form>
    </div>

    <section>
        <p id="welcome-text">Hello, <%= sessionName %> 👋</p>
        <label id="title">Chats</label>
        <input id="find" type="text" placeholder="Search chats..." autocomplete="off">
        <div id="RecpArea"></div>
    </section>

    <section>
        <div id="main">
            <% if (sessionReceiver == null) { %>
                <p class="para" id="selectMsg">Select Recipient to start conversation</p>
            <% } %>

            <div id="videoModal" style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.85);z-index:1000;flex-direction:column;align-items:center;justify-content:center;">
                <div style="display:flex;gap:20px;margin-bottom:20px;">
                    <div style="text-align:center;">
                        <p style="color:white;margin-bottom:6px;">You</p>
                        <video id="localVideo" autoplay muted width="320" height="240" style="border-radius:12px;background:#111;display:block;"></video>
                    </div>
                    <div style="text-align:center;">
                        <p style="color:white;margin-bottom:6px;" id="remoteLabel">Waiting...</p>
                        <video id="remoteVideo" autoplay width="320" height="240" style="border-radius:12px;background:#111;display:block;"></video>
                    </div>
                </div>
                <button onclick="endCall()" style="background:red;color:white;border:none;padding:10px 30px;border-radius:25px;font-size:16px;cursor:pointer;">🔴 End Call</button>
            </div>

            <div class="pro">
                <div style="display:flex;flex-direction:column;">
                    <div id="username">username</div>
                    <span id="header-status"></span>
                </div>
                <button id="video-btn" onclick="startVideoCall()" style="margin-left:auto;">📹</button>
            </div>

            <div id="typing-indicator"></div>
            <div id="chat-area"></div>

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
    const ME             = '<%= sessionUsername %>';
    const SAVED_RECEIVER = '<%= sessionReceiver != null ? sessionReceiver : "" %>';

    let onlineStatusMap  = {};
    let messagesInterval = null;
    let typingTimer      = null;
    let presenceSocket   = null;
    let incomingSocket   = null;

    // POPUP
    const popup = document.getElementById('popup');
    document.getElementById('showpopup').onclick = (e) => {
        e.stopPropagation();
        popup.classList.add('active');
        document.querySelector('.abc').value = '';
        document.getElementById('userbutton').innerHTML = '';
    };
    document.getElementById('btnc').onclick = () => popup.classList.remove('active');
    document.addEventListener('click', (e) => {
        if (!popup.contains(e.target) && e.target.id !== 'showpopup') popup.classList.remove('active');
    });

    // SEARCH USER IN POPUP
    document.querySelector('.abc').addEventListener('keyup', function () {
        const val = this.value.trim();
        const btn = document.getElementById('userbutton');
        if (!val) { btn.innerHTML = ''; return; }
        fetch('validateUser?username=' + encodeURIComponent(val))
            .then(r => r.text())
            .then(data => {
                const found = data.trim();
                if (found && val.toLowerCase() === found.toLowerCase())
                    btn.innerHTML = `<button type="button" onclick="sayHi('${found}')">👋 Say hi! to ${found}</button>`;
                else btn.innerHTML = '<p>User not found</p>';
            }).catch(() => { btn.innerHTML = ''; });
    });

    // SAY HI
    function sayHi(receiver) {
        if (!receiver) return;
        const xhr = new XMLHttpRequest();
        xhr.open('POST', 'sendWelcomeMessage', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200) {
                alert('👋 Message sent to ' + receiver + '!');
                popup.classList.remove('active');
                document.querySelector('.abc').value = '';
                document.getElementById('userbutton').innerHTML = '';
                getReceiver();
            }
        };
        xhr.send('receiver=' + encodeURIComponent(receiver) + '&message=hi');
    }

    // SEND MESSAGE
    function MessageInChats() {
        const msg = document.querySelector('#msgText').value.trim();
        if (!msg) return;
        const xhr = new XMLHttpRequest();
        xhr.open('POST', 'sendMessage', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200) {
                document.querySelector('#msgText').value = '';
                sendTypingStatus(false);
            }
        };
        xhr.send('message=' + encodeURIComponent(msg));
    }
    document.getElementById('send-btn').addEventListener('click', MessageInChats);
    document.getElementById('msgText').addEventListener('keydown', (e) => { if (e.key === 'Enter') MessageInChats(); });
    document.getElementById('msgText').addEventListener('input', () => {
        sendTypingStatus(true);
        clearTimeout(typingTimer);
        typingTimer = setTimeout(() => sendTypingStatus(false), 2000);
    });

    // LOAD RECEIVERS
    function getReceiver() {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', 'getReceivers', true);
        xhr.onload = () => {
            if (xhr.status !== 200 || !xhr.responseText) return;
            let list; try { list = JSON.parse(xhr.responseText); } catch(e) { return; }
            const area = document.querySelector('#RecpArea');
            area.innerHTML = '';
            list.forEach(ro => {
                const online = onlineStatusMap[ro] === true;
                area.innerHTML += `
                    <div class="chatBox" id="chatBox_${ro}">
                        <button class="name" id="nameBtn_${ro}">
                            <span class="user-status ${online ? 'online' : ''}" id="status_${ro}"></span>
                            <img src="images/usericon.png" width="25" height="25" onerror="this.style.display='none'">${ro}
                        </button>
                    </div>`;
            });
            if (SAVED_RECEIVER) highlightSelected(SAVED_RECEIVER);
        };
        xhr.send();
    }
    getReceiver();

    // SEARCH CHATS
    document.getElementById('find').addEventListener('keyup', function () {
        const val = this.value.trim().toLowerCase();
        document.querySelectorAll('#RecpArea .chatBox').forEach(box => {
            const n = box.querySelector('.name');
            box.style.display = (n && n.textContent.trim().toLowerCase().includes(val)) ? 'block' : 'none';
        });
    });

    // LOAD MESSAGES
    function getMessages() {
        const xhr = new XMLHttpRequest();
        xhr.open('GET', 'showChats', true);
        xhr.onload = () => {
            if (xhr.status !== 200 || !xhr.responseText || xhr.responseText.trim() === '') return;
            let msgs; try { msgs = JSON.parse(xhr.responseText); } catch(e) { return; }
            const area = document.getElementById('chat-area');
            const atBottom = area.scrollHeight - area.scrollTop <= area.clientHeight + 60;
            area.innerHTML = '';
            msgs.forEach(obj => {
                // ✅ FIXED: use === for isMe check
                const isMe = obj['sender'] === ME;
                const css  = isMe ? 'colorClass' : 'receiverChat';
                if (obj['message'] && obj['message'].startsWith('__FILE__:')) {
                    const parts = obj['message'].replace('__FILE__:', '').split('::');
                    area.innerHTML += `<p class="${css}">📎 <a href="${parts[0]}" download="${parts[1]||'file'}" style="color:inherit;text-decoration:underline;">${parts[1]||'Download'}</a></p>`;
                } else {
                    area.innerHTML += `<p class="${css}">${escapeHtml(obj['message']||'')}</p>`;
                }
            });
            if (atBottom) area.scrollTop = area.scrollHeight;
        };
        xhr.send();
    }

    function escapeHtml(t) {
        const d = document.createElement('div');
        d.appendChild(document.createTextNode(t));
        return d.innerHTML;
    }

    // SELECT USER
    function selectUser(receiver) {
        fetch('setReceive?receiver=' + encodeURIComponent(receiver)).then(r => {
            if (!r.ok) return;
            document.getElementById('username').innerHTML = receiver;
            Array.from(document.getElementsByClassName('pro')).forEach(p => p.style.display = 'flex');
            const sel = document.getElementById('selectMsg');
            if (sel) sel.style.display = 'none';
            updateHeaderStatus(receiver);
            highlightSelected(receiver);
            // ✅ Clear old interval — no duplicate message fetching
            if (messagesInterval) clearInterval(messagesInterval);
            getMessages();
            messagesInterval = setInterval(getMessages, 1000);
        });
    }

    window.addEventListener('click', (e) => {
        const btn = e.target.closest('.name');
        if (btn) { const r = btn.textContent.trim(); if (r) selectUser(r); }
    });

    function highlightSelected(receiver) {
        document.querySelectorAll('.name').forEach(b => b.style.background = '');
        const btn = document.getElementById('nameBtn_' + receiver);
        if (btn) btn.style.background = '#d9fdd3';
    }

    // FILE SHARING
    document.getElementById('fileInput').addEventListener('change', async function () {
        const file = this.files[0];
        if (!file) return;
        if (file.size > 50*1024*1024) { alert('File too large! Max 50MB.'); return; }
        const fd = new FormData(); fd.append('file', file);
        try {
            const res = await fetch('upload', { method: 'POST', body: fd });
            const data = await res.json();
            if (data.error) { alert(data.error); return; }
            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'sendMessage', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.send('message=' + encodeURIComponent('__FILE__:' + data.url + '::' + data.name));
            this.value = '';
        } catch(e) { alert('File upload failed.'); }
    });

    // PRESENCE (ONLINE + TYPING)
    function connectPresence() {
        if (!ME || ME === 'null') return;
        const ws = window.location.protocol === 'https:' ? 'wss' : 'ws';
        presenceSocket = new WebSocket(`${ws}://${window.location.host}/presence/${ME}`);
        presenceSocket.onopen = () => console.log('✅ Presence connected');
        presenceSocket.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                const cur  = document.getElementById('username').innerHTML.trim();
                if (data.type === 'online') {
                    onlineStatusMap[data.user] = true;
                    updateStatusDot(data.user, true);
                    if (data.user === cur) updateHeaderStatus(cur);
                } else if (data.type === 'offline') {
                    onlineStatusMap[data.user] = false;
                    updateStatusDot(data.user, false);
                    if (data.user === cur) updateHeaderStatus(cur);
                } else if (data.type === 'onlineList') {
                    // ✅ Restore all online statuses after refresh
                    data.users.forEach(u => { onlineStatusMap[u] = true; updateStatusDot(u, true); });
                    if (cur && cur !== 'username') updateHeaderStatus(cur);
                } else if (data.type === 'typing') {
                    if (data.from === cur) showTypingIndicator(data.isTyping, data.from);
                }
            } catch(e) { console.error('Presence error:', e); }
        };
        presenceSocket.onclose = () => setTimeout(connectPresence, 3000);
        presenceSocket.onerror = (e) => console.error('Presence error:', e);
    }
    connectPresence();

    function updateStatusDot(u, online) {
        const dot = document.getElementById('status_' + u);
        if (dot) { if (online) dot.classList.add('online'); else dot.classList.remove('online'); }
    }
    function updateHeaderStatus(u) {
        const el = document.getElementById('header-status');
        if (!el) return;
        if (onlineStatusMap[u]) { el.textContent = '🟢 Online'; el.style.color = '#25d366'; }
        else { el.textContent = '⚫ Offline'; el.style.color = '#999'; }
    }
    function showTypingIndicator(isTyping, from) {
        document.getElementById('typing-indicator').textContent = isTyping ? from + ' is typing...' : '';
    }
    function sendTypingStatus(isTyping) {
        const r = document.getElementById('username').innerHTML.trim();
        if (!r || r === 'username' || !presenceSocket || presenceSocket.readyState !== WebSocket.OPEN) return;
        presenceSocket.send(JSON.stringify({ type: 'typing', to: r, from: ME, isTyping }));
    }

    // VIDEO CALL
    const rtcConfig = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }, { urls: 'stun:stun1.l.google.com:19302' }] };
    let peerConn = null, localStream = null, signalSock = null;

    function connectIncomingSignal() {
        if (!ME || ME === 'null') return;
        const ws = window.location.protocol === 'https:' ? 'wss' : 'ws';
        incomingSocket = new WebSocket(`${ws}://${window.location.host}/signal/incoming_${ME}`);
        incomingSocket.onmessage = async (event) => {
            const sig = JSON.parse(event.data);
            if (sig.type === 'call-request' && confirm(`📹 Incoming call from ${sig.caller}. Accept?`)) {
                document.getElementById('videoModal').style.display = 'flex';
                document.getElementById('remoteLabel').innerText = sig.caller;
                initWebRTC([ME, sig.caller].sort().join('_'), false);
            }
        };
        incomingSocket.onclose = () => setTimeout(connectIncomingSignal, 3000);
    }
    connectIncomingSignal();

    function startVideoCall() {
        const receiver = document.getElementById('username').innerHTML.trim();
        if (!receiver || receiver === 'username') { alert('Please select a recipient first.'); return; }
        document.getElementById('videoModal').style.display = 'flex';
        document.getElementById('remoteLabel').innerText = receiver;
        const ws = window.location.protocol === 'https:' ? 'wss' : 'ws';
        const notify = new WebSocket(`${ws}://${window.location.host}/signal/incoming_${receiver}`);
        notify.onopen = () => { notify.send(JSON.stringify({ type: 'call-request', caller: ME })); setTimeout(() => notify.close(), 1000); };
        initWebRTC([ME, receiver].sort().join('_'), true);
    }

    async function initWebRTC(roomId, isInitiator) {
        const ws = window.location.protocol === 'https:' ? 'wss' : 'ws';
        peerConn = new RTCPeerConnection(rtcConfig);
        try {
            localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
            document.getElementById('localVideo').srcObject = localStream;
            localStream.getTracks().forEach(t => peerConn.addTrack(t, localStream));
        } catch(e) { alert('Could not access camera/mic.'); endCall(); return; }
        signalSock = new WebSocket(`${ws}://${window.location.host}/signal/${roomId}`);
        peerConn.onicecandidate = (e) => { if (e.candidate && signalSock.readyState === WebSocket.OPEN) signalSock.send(JSON.stringify({ type: 'ice-candidate', data: e.candidate })); };
        peerConn.ontrack = (e) => { document.getElementById('remoteVideo').srcObject = e.streams[0]; };
        signalSock.onmessage = async (event) => {
            const sig = JSON.parse(event.data);
            if (sig.type === 'offer') {
                await peerConn.setRemoteDescription(new RTCSessionDescription(sig.data));
                const ans = await peerConn.createAnswer();
                await peerConn.setLocalDescription(ans);
                signalSock.send(JSON.stringify({ type: 'answer', data: ans }));
            } else if (sig.type === 'answer') {
                await peerConn.setRemoteDescription(new RTCSessionDescription(sig.data));
            } else if (sig.type === 'ice-candidate') {
                try { await peerConn.addIceCandidate(new RTCIceCandidate(sig.data)); } catch(e) {}
            }
        };
        if (isInitiator) signalSock.onopen = async () => { const offer = await peerConn.createOffer(); await peerConn.setLocalDescription(offer); signalSock.send(JSON.stringify({ type: 'offer', data: offer })); };
    }

    function endCall() {
        if (peerConn) { peerConn.close(); peerConn = null; }
        if (localStream) { localStream.getTracks().forEach(t => t.stop()); localStream = null; }
        if (signalSock) { signalSock.close(); signalSock = null; }
        document.getElementById('localVideo').srcObject = null;
        document.getElementById('remoteVideo').srcObject = null;
        document.getElementById('videoModal').style.display = 'none';
    }

    // RESTORE ON REFRESH
    window.addEventListener('load', () => {
        if (!SAVED_RECEIVER) return;
        document.getElementById('username').innerHTML = SAVED_RECEIVER;
        Array.from(document.getElementsByClassName('pro')).forEach(p => p.style.display = 'flex');
        const sel = document.getElementById('selectMsg'); if (sel) sel.style.display = 'none';
        getMessages();
        if (messagesInterval) clearInterval(messagesInterval);
        messagesInterval = setInterval(getMessages, 1000);
        setTimeout(() => { highlightSelected(SAVED_RECEIVER); updateHeaderStatus(SAVED_RECEIVER); }, 700);
    });
</script>
</body>
</html>
