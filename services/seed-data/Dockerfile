FROM alpine:3.19

RUN apk add --no-cache \
    postgresql-client \
    apache2-utils \
    python3 \
    py3-pip

WORKDIR /app

COPY make-data.py .
COPY generate-votes.sh .
COPY entrypoint.sh .

# Generate posta / postb at build time
RUN python3 make-data.py \
 && chmod +x generate-votes.sh entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
