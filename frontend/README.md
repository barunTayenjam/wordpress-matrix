# WordPress Matrix Frontend

A modern web interface for the WordPress Development Platform that provides an intuitive dashboard for managing WordPress sites and services.

## Features

- 🎯 **Dashboard Overview**: Real-time status of all sites and services
- 🌐 **Site Management**: Create, start, stop, and remove WordPress sites
- 📊 **Service Monitoring**: Track status of database, cache, and development tools
- 💻 **Terminal Interface**: Execute matrix commands directly from the web UI
- 🔄 **Real-time Updates**: Live status updates and notifications
- 📱 **Responsive Design**: Works on desktop, tablet, and mobile devices

## Quick Start

1. Install dependencies:
```bash
cd frontend
npm install
```

2. Start the frontend:
```bash
npm start
```

3. Open your browser:
```
http://localhost:3000
```

## API Endpoints

- `GET /api/sites` - Get all sites and services
- `POST /api/sites/:action` - Execute site commands (create, start, stop, remove, info, url)
- `POST /api/environment/:action` - Execute environment commands (start, stop, restart, status, logs, clean, check)
- `GET /api/status` - Get system status
- `GET /api/help` - Get help information

## Architecture

- **Backend**: Express.js server that wraps the `matrix` command
- **Frontend**: Bootstrap 5 + Vanilla JavaScript
- **Real-time**: WebSocket connections for live updates (planned)
- **Security**: Command validation and sanitization

## Development

### Install Dependencies
```bash
npm install
```

### Development Mode
```bash
npm run dev  # Uses nodemon for auto-reloading
```

### Production Mode
```bash
npm start
```

## Configuration

The frontend uses environment variables:
- `PORT` - Frontend server port (default: 3000)
- Matrix script path is relative to the parent directory

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Security

- Commands are validated before execution
- Input sanitization prevents injection attacks
- CORS configuration for secure API access
- Error messages are sanitized for display

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details