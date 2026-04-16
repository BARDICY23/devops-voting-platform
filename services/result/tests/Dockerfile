FROM node:20-alpine

# Install Chrome and matching dependencies for Puppeteer
RUN apk add --no-cache \
      chromium \
      nss \
      freetype \
      harfbuzz \
      ca-certificates \
      ttf-freefont

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /app

# Initialize a package and install Puppeteer explicitly
RUN npm init -y && npm install puppeteer@latest

COPY . /app

CMD ["node", "test.js"]
