FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install package dependencies
COPY package*.json ./
RUN npm install

# Copy application files
COPY . .

# Make matrix script executable
COPY ../matrix /matrix
RUN chmod +x /matrix

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js || exit 1

# Start the application
CMD ["npm", "start"]