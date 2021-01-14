FROM alpine:latest

MAINTAINER Joyce Freitas <jfreitas@student.19.fr>

RUN apk update && apk upgrade
RUN apk add libc6-compat

RUN wget https://dl.influxdata.com/telegraf/releases/telegraf-1.13.3-static_linux_amd64.tar.gz \
    && tar -C . -xzf telegraf-1.13.3-static_linux_amd64.tar.gz

RUN chmod +x telegraf/*
RUN cp telegraf/telegraf /usr/bin/

# make sure we can copy our conf file in the right location
RUN mkdir /etc/telegraf
#RUN mv telegraf/telegraf.conf /etc/telegraf/telegraf.conf


COPY ./telegraf.conf /etc/telegraf/telegraf.conf


COPY ./start.sh /tmp/
RUN chmod +x /tmp/start.sh
CMD /tmp/start.sh
