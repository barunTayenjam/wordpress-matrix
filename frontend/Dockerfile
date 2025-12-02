FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install package dependencies
COPY package*.json ./
RUN npm install

# Copy application files
COPY . .
RUN chmod +x /app/matrix
# Mount matrix script from host at runtime instead of build time
# The script will be mounted as a volume in docker-compose

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js || exit 1

# Start the application
CMD ["npm", "start"]