#!/bin/bash

# Wisecow - A simple web server that serves fortune cookies with cowsay

RESPONSE="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"

# Function to generate cow saying a fortune
generate_fortune() {
    fortune | cowsay
}

# Function to handle HTTP requests
handle_request() {
    echo -e "$RESPONSE"
    cat << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Wisecow</title>
    <style>
        body {
            font-family: monospace;
            background-color: #f0f0f0;
            margin: 40px;
            text-align: center;
        }
        pre {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            display: inline-block;
            text-align: left;
        }
        h1 { color: #333; }
        .refresh {
            margin-top: 20px;
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <h1>🐄 Wisecow - Fortune Teller 🐄</h1>
    <pre>$(generate_fortune)</pre>
    <br>
    <a href="/" class="refresh">Get Another Fortune</a>
</body>
</html>
EOF
}

# Start the server
echo "Starting Wisecow server on port 4499..."
while true; do
    echo -e "$(handle_request)" | nc -l -p 4499 -q 1
done