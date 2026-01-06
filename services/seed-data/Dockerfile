FROM alpine:3.19

RUN apk add --no-cache \
    postgresql-client \
    apache2-utils \
    curl

WORKDIR /app
COPY . .

RUN chmod +x entrypoint.sh generate-votes.sh

ENTRYPOINT ["./entrypoint.sh"]
