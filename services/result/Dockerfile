FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install -g npm@10.8.1 && npm install --omit=dev && npm cache clean --force

COPY . .

# Create non-root user with numeric UID (PSA-compliant)
RUN addgroup -g 10001 appgroup \
 && adduser -D -u 10001 -G appgroup appuser \
 && chown -R 10001:10001 /app

USER 10001

EXPOSE 8081
CMD ["node", "server.js"]

