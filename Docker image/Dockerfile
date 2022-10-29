FROM prom/node-exporter:v1.4.0 as build 
FROM alpine as runtime 

COPY --from=build /bin/node_exporter /bin/node_exporter

RUN apk update && apk add curl postgresql-client 

RUN mkdir -p /home/scripts 
COPY run.sh /home/scripts/run.sh 

USER nobody

ENTRYPOINT  ["sh", "/home/scripts/run.sh" ]
EXPOSE 9100
