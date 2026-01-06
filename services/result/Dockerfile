ARG BUILD_VERSION=unknown
ARG GIT_COMMIT_SHA=unknown
ARG REPO_URL=https://github.com/BARDICY23/devops-voting-app

FROM node:20-alpine

# Create non-root user
RUN useradd -m appuser
WORKDIR /app

# Copy package files and install production deps
COPY package*.json ./
RUN npm ci --only=production

# Copy app source (including views/)
COPY . .

# Fix permissions
RUN chown -R appuser:appuser /app
USER appuser

# Expose result port
EXPOSE 4000

LABEL org.opencontainers.image.title="Voting App Result Service (Node.js)" \
      org.opencontainers.image.version=$BUILD_VERSION \
      org.opencontainers.image.revision=$GIT_COMMIT_SHA \
      org.opencontainers.image.source=$REPO_URL

# Start the server (server.js should listen on 0.0.0.0:8081)
CMD ["node", "server.js"]
