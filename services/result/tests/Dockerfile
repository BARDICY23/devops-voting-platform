FROM node:20-alpine

RUN apk update && apk add --no-cache \
    ca-certificates \
    bzip2 \
    curl \
    fontconfig
RUN yarn global add phantomjs-prebuilt
ADD . /app
WORKDIR /app
CMD ["/app/tests.sh"]
