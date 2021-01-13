FROM alpine:latest

MAINTAINER Joyce Freitas <jfreitas@student.19.fr>

RUN apk update && apk upgrade
RUN apk add influxdb


EXPOSE 8086

COPY ./start.sh /tmp/
RUN chmod +x /tmp/start.sh
CMD /tmp/start.sh
