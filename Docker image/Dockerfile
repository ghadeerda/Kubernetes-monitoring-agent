FROM alpine:latest

RUN apk --no-cache add curl nano postgresql-client

WORKDIR /app

COPY nodeScraper.sh /app/nodeScraper.sh
COPY appScraper.sh /app/appScraper.sh
COPY startup.sh /app/startup.sh

RUN chmod +x /app/nodeScraper.sh /app/appScraper.sh /app/startup.sh

CMD ["/app/startup.sh"]
