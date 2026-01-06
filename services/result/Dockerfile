FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Create non-root user with numeric UID (PSA-compliant)
RUN addgroup -g 10001 appgroup \
 && adduser -D -u 10001 -G appgroup appuser \
 && chown -R 10001:10001 /app

USER 10001

EXPOSE 4000
CMD ["node", "server.js"]

