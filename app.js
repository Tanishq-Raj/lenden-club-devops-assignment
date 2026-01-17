const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>DevOps Assignment - Web App</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
          padding: 20px;
        }
        .container {
          background: rgba(255, 255, 255, 0.95);
          border-radius: 20px;
          padding: 40px;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
          max-width: 600px;
          width: 100%;
          backdrop-filter: blur(10px);
        }
        h1 {
          color: #667eea;
          margin-bottom: 10px;
          font-size: 2.5em;
          text-align: center;
        }
        .subtitle {
          color: #666;
          text-align: center;
          margin-bottom: 30px;
          font-size: 1.1em;
        }
        .info-card {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 20px;
          border-radius: 10px;
          margin: 20px 0;
        }
        .info-item {
          margin: 10px 0;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .label {
          font-weight: bold;
          opacity: 0.9;
        }
        .value {
          background: rgba(255, 255, 255, 0.2);
          padding: 5px 15px;
          border-radius: 5px;
          font-family: 'Courier New', monospace;
        }
        .status {
          text-align: center;
          margin-top: 20px;
          padding: 15px;
          background: #10b981;
          color: white;
          border-radius: 10px;
          font-weight: bold;
          font-size: 1.2em;
        }
        .footer {
          text-align: center;
          margin-top: 20px;
          color: #666;
          font-size: 0.9em;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 DevOps Assignment</h1>
        <p class="subtitle">Containerized Web Application</p>
        
        <div class="info-card">
          <div class="info-item">
            <span class="label">Hostname:</span>
            <span class="value">${os.hostname()}</span>
          </div>
          <div class="info-item">
            <span class="label">Platform:</span>
            <span class="value">${os.platform()}</span>
          </div>
          <div class="info-item">
            <span class="label">Node Version:</span>
            <span class="value">${process.version}</span>
          </div>
          <div class="info-item">
            <span class="label">Uptime:</span>
            <span class="value">${Math.floor(process.uptime())}s</span>
          </div>
        </div>
        
        <div class="status">
          ✅ Application Running Successfully
        </div>
        
        <div class="footer">
          DevSecOps Pipeline | Terraform + Jenkins + Trivy
        </div>
      </div>
    </body>
    </html>
  `;
  res.send(html);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    hostname: os.hostname()
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  res.json({
    application: 'DevOps Assignment Web App',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    hostname: os.hostname(),
    platform: os.platform(),
    nodeVersion: process.version,
    uptime: process.uptime()
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📍 Access the application at http://localhost:${PORT}`);
  console.log(`💚 Health check available at http://localhost:${PORT}/health`);
});
