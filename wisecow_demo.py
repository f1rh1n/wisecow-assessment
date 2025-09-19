#!/usr/bin/env python3

"""
Wisecow Demo - Windows Compatible Version
A simple HTTP server that serves fortune cookies with ASCII cow art
"""

import http.server
import socketserver
import random
from datetime import datetime

# Port to run the server on
PORT = 4499

# Sample fortunes (simulating the Unix 'fortune' command)
FORTUNES = [
    "A journey of a thousand miles begins with a single step.",
    "The only way to do great work is to love what you do.",
    "Innovation distinguishes between a leader and a follower.",
    "Life is what happens to you while you're busy making other plans.",
    "The future belongs to those who believe in the beauty of their dreams.",
    "It is during our darkest moments that we must focus to see the light.",
    "The only impossible journey is the one you never begin.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "Don't watch the clock; do what it does. Keep going.",
    "Whether you think you can or you think you can't, you're right.",
    "The way to get started is to quit talking and begin doing.",
    "Don't let yesterday take up too much of today.",
    "You learn more from failure than from success.",
    "If you are working on something that you really care about, you don't have to be pushed.",
    "Experience is the teacher of all things."
]

# ASCII cow art (simulating cowsay)
def generate_cowsay(message):
    lines = message.split('\n')
    max_length = max(len(line) for line in lines) if lines else 0

    # Create the speech bubble
    bubble = []
    if len(lines) == 1:
        bubble.append(f" {'_' * (max_length + 2)} ")
        bubble.append(f"< {message} >")
        bubble.append(f" {'-' * (max_length + 2)} ")
    else:
        bubble.append(f" {'_' * (max_length + 2)} ")
        for i, line in enumerate(lines):
            if i == 0:
                bubble.append(f"/ {line.ljust(max_length)} \\")
            elif i == len(lines) - 1:
                bubble.append(f"\\ {line.ljust(max_length)} /")
            else:
                bubble.append(f"| {line.ljust(max_length)} |")
        bubble.append(f" {'-' * (max_length + 2)} ")

    # Add the cow
    cow = """
        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||
"""

    return '\n'.join(bubble) + cow

def get_fortune():
    """Get a random fortune message"""
    return random.choice(FORTUNES)

class WisecowHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

            # Generate fortune with cowsay
            fortune_text = get_fortune()
            cow_fortune = generate_cowsay(fortune_text)

            # Create HTML response
            html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <title>🐄 Wisecow - Fortune Teller</title>
    <meta charset="UTF-8">
    <style>
        body {{
            font-family: 'Courier New', monospace;
            background-color: #f0f8ff;
            margin: 40px;
            text-align: center;
            background-image: linear-gradient(45deg, #f0f8ff 25%, transparent 25%),
                            linear-gradient(-45deg, #f0f8ff 25%, transparent 25%),
                            linear-gradient(45deg, transparent 75%, #f0f8ff 75%),
                            linear-gradient(-45deg, transparent 75%, #f0f8ff 75%);
            background-size: 20px 20px;
            background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
        }}
        .container {{
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #2c3e50;
            margin-bottom: 30px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }}
        .fortune-box {{
            background-color: #1e1e1e;
            color: #00ff00;
            padding: 25px;
            border-radius: 10px;
            margin: 20px 0;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            text-align: left;
            overflow-x: auto;
            border: 2px solid #333;
        }}
        .cow-art {{
            white-space: pre;
            line-height: 1.2;
        }}
        .refresh-btn {{
            display: inline-block;
            margin-top: 20px;
            padding: 12px 25px;
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-weight: bold;
            transition: all 0.3s ease;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }}
        .refresh-btn:hover {{
            background: linear-gradient(45deg, #45a049, #4CAF50);
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.3);
        }}
        .info {{
            margin-top: 30px;
            padding: 15px;
            background-color: #e8f4fd;
            border-left: 4px solid #2196F3;
            border-radius: 5px;
            text-align: left;
        }}
        .timestamp {{
            color: #666;
            font-size: 12px;
            margin-top: 15px;
        }}
        .status {{
            position: absolute;
            top: 10px;
            right: 10px;
            background: #4CAF50;
            color: white;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 12px;
        }}
    </style>
</head>
<body>
    <div class="status">● ONLINE</div>
    <div class="container">
        <h1>🐄 Wisecow - Fortune Teller 🐄</h1>
        <p>Welcome to Wisecow! Get your daily dose of wisdom from our wise bovine friend.</p>

        <div class="fortune-box">
            <div class="cow-art">{cow_fortune}</div>
        </div>

        <a href="/" class="refresh-btn">🎲 Get Another Fortune</a>

        <div class="info">
            <h3>🎯 About This Demo</h3>
            <p><strong>Application:</strong> Wisecow Fortune Teller</p>
            <p><strong>Version:</strong> 1.0.0 (Windows Demo)</p>
            <p><strong>Status:</strong> Running on port {PORT}</p>
            <p><strong>Technology:</strong> Python HTTP Server</p>
            <p><strong>Features:</strong> Random fortunes with ASCII cow art</p>
        </div>

        <div class="timestamp">
            Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        </div>
    </div>
</body>
</html>
"""

            self.wfile.write(html_content.encode('utf-8'))

        elif self.path == '/health':
            # Health check endpoint
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            health_response = '{"status": "healthy", "service": "wisecow", "timestamp": "' + datetime.now().isoformat() + '"}'
            self.wfile.write(health_response.encode('utf-8'))

        else:
            # 404 for other paths
            self.send_response(404)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'<h1>404 - Page Not Found</h1><p><a href="/">Go back to Wisecow</a></p>')

def main():
    """Start the Wisecow server"""
    try:
        with socketserver.TCPServer(("", PORT), WisecowHandler) as httpd:
            print(f"🐄 Wisecow server starting...")
            print(f"📡 Server running on: http://localhost:{PORT}")
            print(f"🔗 Open in browser: http://localhost:{PORT}")
            print(f"💊 Health check: http://localhost:{PORT}/health")
            print(f"🛑 Press Ctrl+C to stop the server")
            print("=" * 50)
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")

if __name__ == "__main__":
    main()