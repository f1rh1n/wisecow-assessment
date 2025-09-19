#!/usr/bin/env node

/**
 * Wisecow Demo - Node.js Version
 * A simple HTTP server that serves fortune cookies with ASCII cow art
 */

const http = require('http');
const url = require('url');

// Configuration
const PORT = 8080;
const HOST = 'localhost';

// Sample fortunes (simulating the Unix 'fortune' command)
const FORTUNES = [
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
    "Experience is the teacher of all things.",
    "The best time to plant a tree was 20 years ago. The second best time is now.",
    "Your limitation—it's only your imagination.",
    "Push yourself, because no one else is going to do it for you.",
    "Great things never come from comfort zones.",
    "Dream it. Wish it. Do it."
];

/**
 * Generate ASCII cow art with speech bubble (simulating cowsay)
 */
function generateCowsay(message) {
    const lines = message.split('\n');
    const maxLength = Math.max(...lines.map(line => line.length));

    let bubble = [];

    if (lines.length === 1) {
        const padding = '_'.repeat(maxLength + 2);
        bubble.push(` ${padding} `);
        bubble.push(`< ${message} >`);
        bubble.push(` ${'-'.repeat(maxLength + 2)} `);
    } else {
        const padding = '_'.repeat(maxLength + 2);
        bubble.push(` ${padding} `);

        lines.forEach((line, i) => {
            const paddedLine = line.padEnd(maxLength);
            if (i === 0) {
                bubble.push(`/ ${paddedLine} \\`);
            } else if (i === lines.length - 1) {
                bubble.push(`\\ ${paddedLine} /`);
            } else {
                bubble.push(`| ${paddedLine} |`);
            }
        });

        bubble.push(` ${'-'.repeat(maxLength + 2)} `);
    }

    const cow = `
        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||`;

    return bubble.join('\n') + cow;
}

/**
 * Get a random fortune
 */
function getFortune() {
    return FORTUNES[Math.floor(Math.random() * FORTUNES.length)];
}

/**
 * Generate HTML page
 */
function generateHTML() {
    const fortune = getFortune();
    const cowArt = generateCowsay(fortune);
    const timestamp = new Date().toLocaleString();

    return `<!DOCTYPE html>
<html>
<head>
    <title>🐄 Wisecow - Fortune Teller</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Courier New', monospace;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            max-width: 800px;
            width: 100%;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        .container::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 5px;
            background: linear-gradient(90deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4, #ffecd2);
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 10px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
            animation: bounce 2s infinite;
        }
        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-style: italic;
        }
        .fortune-container {
            background: #1a1a1a;
            color: #00ff41;
            padding: 30px;
            border-radius: 15px;
            margin: 30px 0;
            border: 3px solid #333;
            box-shadow: inset 0 0 20px rgba(0,255,65,0.1);
            position: relative;
        }
        .fortune-container::before {
            content: '💻';
            position: absolute;
            top: 10px;
            left: 15px;
            font-size: 1.2em;
        }
        .cow-art {
            white-space: pre;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            line-height: 1.2;
            text-align: left;
            overflow-x: auto;
            text-shadow: 0 0 10px rgba(0,255,65,0.3);
        }
        .controls {
            margin: 30px 0;
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            display: inline-block;
            padding: 12px 25px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: bold;
            transition: all 0.3s ease;
            border: none;
            cursor: pointer;
            font-family: inherit;
            font-size: 16px;
        }
        .btn-primary {
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white;
            box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);
        }
        .btn-primary:hover {
            transform: translateY(-3px);
            box-shadow: 0 7px 25px rgba(76, 175, 80, 0.4);
        }
        .btn-secondary {
            background: linear-gradient(45deg, #2196F3, #1976D2);
            color: white;
            box-shadow: 0 4px 15px rgba(33, 150, 243, 0.3);
        }
        .btn-secondary:hover {
            transform: translateY(-3px);
            box-shadow: 0 7px 25px rgba(33, 150, 243, 0.4);
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .stat-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
        }
        .stat-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .stat-value {
            font-size: 18px;
            font-weight: bold;
            color: #2c3e50;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #666;
            font-size: 12px;
        }
        .status-indicator {
            position: absolute;
            top: 20px;
            right: 20px;
            background: #4CAF50;
            color: white;
            padding: 8px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .status-dot {
            width: 8px;
            height: 8px;
            background: white;
            border-radius: 50%;
            animation: pulse 1.5s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        @media (max-width: 600px) {
            .container { padding: 20px; margin: 10px; }
            h1 { font-size: 2em; }
            .controls { flex-direction: column; align-items: center; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="status-indicator">
            <div class="status-dot"></div>
            ONLINE
        </div>

        <h1>🐄 Wisecow Fortune Teller 🐄</h1>
        <p class="subtitle">Your Daily Dose of Wisdom from Our Wise Bovine Oracle</p>

        <div class="fortune-container">
            <div class="cow-art">${cowArt.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</div>
        </div>

        <div class="controls">
            <a href="/" class="btn btn-primary">🎲 Get New Fortune</a>
            <a href="/health" class="btn btn-secondary">💊 Health Check</a>
        </div>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-label">Service</div>
                <div class="stat-value">Wisecow v1.0</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Runtime</div>
                <div class="stat-value">Node.js ${process.version}</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Port</div>
                <div class="stat-value">${PORT}</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Status</div>
                <div class="stat-value">✅ Active</div>
            </div>
        </div>

        <div class="footer">
            <p>🕒 Generated at: ${timestamp}</p>
            <p>🐄 Powered by Wisecow Technology | 🎯 Demo Version for Windows</p>
        </div>
    </div>

    <script>
        // Auto-refresh every 30 seconds if user is idle
        let autoRefreshTimer;

        function resetAutoRefresh() {
            clearTimeout(autoRefreshTimer);
            autoRefreshTimer = setTimeout(() => {
                window.location.reload();
            }, 30000);
        }

        // Reset timer on user activity
        ['click', 'mousemove', 'keypress'].forEach(event => {
            document.addEventListener(event, resetAutoRefresh);
        });

        resetAutoRefresh();

        // Add some sparkle effect
        function createSparkle() {
            const sparkle = document.createElement('div');
            sparkle.innerHTML = '✨';
            sparkle.style.position = 'fixed';
            sparkle.style.left = Math.random() * window.innerWidth + 'px';
            sparkle.style.top = Math.random() * window.innerHeight + 'px';
            sparkle.style.fontSize = Math.random() * 20 + 10 + 'px';
            sparkle.style.pointerEvents = 'none';
            sparkle.style.zIndex = '1000';
            sparkle.style.animation = 'sparkleFloat 3s ease-out forwards';

            document.body.appendChild(sparkle);

            setTimeout(() => sparkle.remove(), 3000);
        }

        // Add sparkles occasionally
        setInterval(createSparkle, 5000);

        // Add CSS animation for sparkles
        const style = document.createElement('style');
        style.textContent = \`
            @keyframes sparkleFloat {
                0% { opacity: 0; transform: translateY(0px) rotate(0deg); }
                50% { opacity: 1; }
                100% { opacity: 0; transform: translateY(-100px) rotate(360deg); }
            }
        \`;
        document.head.appendChild(style);
    </script>
</body>
</html>`;
}

/**
 * Handle HTTP requests
 */
function handleRequest(req, res) {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;

    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    console.log(`${new Date().toISOString()} - ${req.method} ${pathname} - ${req.connection.remoteAddress}`);

    if (pathname === '/' || pathname === '/index.html') {
        // Serve main page
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(generateHTML());

    } else if (pathname === '/health') {
        // Health check endpoint
        const healthData = {
            status: 'healthy',
            service: 'wisecow',
            version: '1.0.0',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            platform: process.platform,
            nodeVersion: process.version
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(healthData, null, 2));

    } else if (pathname === '/api/fortune') {
        // API endpoint for fortune
        const fortune = getFortune();
        const cowArt = generateCowsay(fortune);

        const response = {
            fortune,
            cowArt,
            timestamp: new Date().toISOString()
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(response, null, 2));

    } else if (pathname === '/favicon.ico') {
        // Simple favicon response
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('🐄');

    } else {
        // 404 for unknown paths
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end(`
            <html>
                <head><title>404 - Not Found</title></head>
                <body style="font-family: monospace; text-align: center; padding: 50px;">
                    <h1>🐄 Moo! Page Not Found</h1>
                    <p>The cow couldn't find what you're looking for.</p>
                    <a href="/" style="color: #4CAF50; text-decoration: none; font-weight: bold;">🏠 Go Home</a>
                </body>
            </html>
        `);
    }
}

/**
 * Start the server
 */
function startServer() {
    const server = http.createServer(handleRequest);

    server.listen(PORT, HOST, () => {
        console.log('🐄 Wisecow Server Starting...');
        console.log('=' .repeat(50));
        console.log(`📡 Server URL: http://${HOST}:${PORT}`);
        console.log(`🔗 Open in browser: http://localhost:${PORT}`);
        console.log(`💊 Health check: http://localhost:${PORT}/health`);
        console.log(`🚀 API endpoint: http://localhost:${PORT}/api/fortune`);
        console.log('🛑 Press Ctrl+C to stop the server');
        console.log('=' .repeat(50));
        console.log('📝 Server logs:');
    });

    server.on('error', (err) => {
        if (err.code === 'EADDRINUSE') {
            console.error(`❌ Port ${PORT} is already in use. Please try a different port.`);
        } else {
            console.error('❌ Server error:', err.message);
        }
        process.exit(1);
    });

    // Graceful shutdown
    process.on('SIGINT', () => {
        console.log('\\n🛑 Received shutdown signal. Stopping server...');
        server.close(() => {
            console.log('✅ Server stopped gracefully.');
            process.exit(0);
        });
    });

    process.on('SIGTERM', () => {
        console.log('\\n🛑 Received termination signal. Stopping server...');
        server.close(() => {
            console.log('✅ Server terminated gracefully.');
            process.exit(0);
        });
    });
}

// Start the server
if (require.main === module) {
    startServer();
}

module.exports = { generateCowsay, getFortune, handleRequest };