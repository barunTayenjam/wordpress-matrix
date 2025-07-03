FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    inotify-tools \
    docker-cli \
    && rm -rf /var/cache/apk/*

# Install Node.js tools
RUN npm install -g \
    nodemon \
    browser-sync \
    chokidar-cli

# Create app directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy application files
COPY . .

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

ENTRYPOINT ["/app/scripts/entrypoint.sh"]