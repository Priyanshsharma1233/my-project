<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home</title>
    <link rel="stylesheet" href="styles/all.min.css">
    <link rel="stylesheet" href="styles/home.css">
    <script src="scripts/all.min.js"></script>
   </head>
<body>
    <main>
        <section>
            <div class="btn top">
                <i class="fa-regular fa-message" style="font-size: 25px; color:white; margin-bottom:20px ;"></i>
                <i class="fa-regular fa-comment-dots" style="font-size: 25px; color:white; margin-bottom:20px;"></i>
                <button type="button" id="showpopup"><i class="fa-solid fa-plus" style="font-size: 25px;color: white; margin-bottom: 20px;"></i></button>
                <div id="popup">
                    <div id="title-bar">
                        <span>Add Recipient</span>

                    </div>
                    <form>
                        <input type="text" name="username" placeholder="username" class="abc">
                        <div id="userbutton"></div>
                        <button id="btnc">close</button>
                    </form>
                </div>
            </div>
            <div class="btn bottom">
                <a href="logout"><i class="fa-solid fa-arrow-right-from-bracket" style="font-size: 25px;color: white;"></a></i>
            </div>
        </section>
        <section>

                <% if((String)request.getSession().getAttribute("username") != null){ %>
                        <p style="color: green;">Hello, <%= (String)request.getSession().getAttribute("name") %></p>
                    <% }
                    else {
                        response.sendRedirect("index.jsp");
                    } %>

            <label id="title">Chats</label>
            <input id="find" type="text" placeholder="Search..">
            <div id="RecpArea">

            </div>
        </section>
        <section>
            <div id="main">

                <% if((String)request.getSession().getAttribute("receiver") == null){ %>
                    <p class="para">Select Recipient to start conversion</p>
                <% }
                %>
                    <div class="pro">
                                    <div id="username">username</div>
                                </div>
                                <div id="chat-area">

                                </div>
                                <div class="pro">
                                    <input type="text" name="message" placeholder="Message" id="msgText">
                                    <button id="send-btn"><img src="images/send.png" height="20px" width="20px"></button>

                                </div>




            </div>
        </section>
    </main>
    <script>
        document.getElementById('showpopup').addEventListener('click',function(){
            document.getElementById('popup').style.transform = 'scale(1)'
        })

        document.getElementById('btnc').addEventListener('click',function(){
            document.getElementById('popup').style.transform = 'scale(0)'
        })


         document.querySelector('.abc').addEventListener('keyup', function() {
            var url = "validateUser?username=" + document.querySelector('.abc').value;
            fetch(url)
                .then(response => response.text())
                .then(data => {
                    if (document.querySelector('.abc').value == data)
                        document.getElementById('userbutton').innerHTML = '<button type="button" onclick="sendMessage()"> Say hi! to ' + data + '</button>'
                }
                )
                .catch(error => console.error('Error:', error));
        });

        function sendMessage(){
            var receiver = document.querySelector('.abc').value
            console.log(receiver)
            var message = "hi"
            var xhr = new XMLHttpRequest()
            xhr.open("POST", "sendWelcomeMessage", true)
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
            xhr.onreadystatechange = function(){
                if (xhr.readyState === 4 && xhr.status === 200){
                    alert("Message send")
                    // getReceiver()
                }
            }
            var data = "receiver="+receiver + "&message=" + message
            xhr.send(data);
        }

        function MessageInChats(){
            //var receiver = 'him123'
            var message = document.querySelector('#msgText').value
            var xhr = new XMLHttpRequest()
            xhr.open("POST", "sendMessage",true)
            xhr.setRequestHeader("content-type", "application/x-www-form-urlencoded")
            xhr.onreadystatechange = function(){
                if(xhr.readyState === 4 && xhr.status === 200){
                //alert("Message send")
                }
            }
            var data = "message=" + message
            xhr.send(data)
        }


        function getMsg(){
        try{
         document.querySelector('#send-btn') .addEventListener('click', MessageInChats)
        }
        catch(e){}
        }
        setInterval(getMsg, 1000)
        function getReceiver(){
            console.log("Called get receiver")
            var xhr = new XMLHttpRequest()
            xhr.open("POST", "getReceivers", true)
            xhr.onload = function(){
                if (xhr.readyState === 4 && xhr.status === 200){
                    responseObject = JSON.parse(xhr.responseText)
                    let area = document.querySelector('#RecpArea')
                    for (let ro in responseObject){
                        msg = `<div id="Box">
                            <button class="name"><img src="images/usericon.png" width="25px" height="25px">${responseObject[ro]}</button><hr>
                        </div>`
                        area.innerHTML += msg
                    }
                }
            }
            xhr.send(null)
        }
        getReceiver();


        function getMessages(){
            var xhr = new XMLHttpRequest()
            xhr.open("GET", 'showChats', true)
            xhr.onload = function(){
                if(xhr.readyState === 4 && xhr.status === 200){
                    var messages = JSON.parse(xhr.responseText)
                    //console.log(messages)
                    let area = document.getElementById('chat-area')
                    area.innerHTML = ''
                    for (obj of messages){
                        //area.innerHTML += obj['message']+"<br>"
                        area.innerHTML += `<p class="${obj['sender']!=document.getElementById('username').innerHTML?'colorClass':'reciverChat'}">${obj['message']}</p>`
                    }
                    }
                }
            xhr.send()
        }





        window.addEventListener('click', async function(e){
            if(e.target.className == 'name'){

                var url = `setReceive?receiver=${e.target.textContent}`
                console.log(url)
                const response = await fetch(url);
                    if (response.ok) {
                    p = document.getElementsByClassName('pro')
                    for (let i =0;i<p.length; i++)
                        p[i].style.display='block'
                        try{
                    document.querySelector('.para').style.display='none'}catch(e){}
                       document.getElementById('username').innerHTML = e.target.textContent
                       window.setInterval(getMessages, 1000)
                }
            }
        })

        function scrollDivToBottom(){
        try{
                    var div = document.getElementById("chat-area")
                    div.scrollTop = div.scrollHeight
                }catch(e){}


                }

                setInterval(scrollDivToBottom, 1000)



    </script>

</body>
</html>