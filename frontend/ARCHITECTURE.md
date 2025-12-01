# Frontend WordPress Matrix Frontend

This directory contains the web frontend for the WordPress Development Platform.

## Architecture

```
frontend/
├── app.js                 # Main Express server
├── views/                 # Handlebars templates
│   ├── layouts/
│   │   └── main.handlebars
│   ├── dashboard.handlebars
│   └── error.handlebars
├── public/                # Static files
│   ├── js/
│   │   └── app.js        # Frontend JavaScript
│   └── css/             # Custom styles (if needed)
├── Dockerfile             # Docker configuration
├── package.json           # Node.js dependencies
├── .env.example           # Environment variables template
├── README.md              # Frontend documentation
└── healthcheck.js         # Health check script
```

## Features

- **Dashboard**: Overview of all sites and services
- **Site Management**: Create, start, stop, remove sites
- **Service Monitoring**: Track database, cache, and tool status
- **Terminal Interface**: Execute matrix commands via web UI
- **Real-time Updates**: Live status and notifications
- **Responsive Design**: Works on all device sizes

## API Integration

The frontend interfaces with the `matrix` command-line tool:
- Executes shell commands using Node.js `spawn`
- Parses output to extract structured data
- Provides REST API endpoints for web interface
- Handles async operations with timeout protection

## Security Considerations

- Command validation and sanitization
- Non-root Docker container execution
- CORS configuration for API access
- Input validation for site creation
- Error message sanitization

## Development Setup

1. Install dependencies:
```bash
cd frontend
npm install
```

2. Copy environment template:
```bash
cp .env.example .env
```

3. Start development server:
```bash
npm run dev
```

4. Access at: `http://localhost:3000`

## Docker Deployment

```bash
# Using frontend-specific compose file
docker-compose -f docker-compose.frontend.yml up -d

# Or integrate with main compose file
docker-compose -f docker-compose.yml -f docker-compose.frontend.yml up -d
```

## Browser Compatibility

- Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- Bootstrap 5 for responsive UI
- Vanilla JavaScript (no jQuery required)