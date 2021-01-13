FROM alpine:latest

MAINTAINER Joyce Freitas <jfreitas@student.19.fr>

RUN apk update && apk upgrade
RUN apk add libc6-compat

RUN wget https://dl.grafana.com/oss/release/grafana-7.3.5.linux-amd64.tar.gz
RUN tar -zxvf grafana-7.3.5.linux-amd64.tar.gz

COPY ./grafana.ini /grafana-7.3.5/conf/defaults.ini
COPY ./sample_datasource.yaml /grafana-7.3.5/conf/provisioning/datasources/
COPY ./sample_dashboard.yaml /grafana-7.3.5/conf/provisioning/dashboards/default.yaml
COPY ./dashboards/* /grafana-7.3.5/dashboards/


EXPOSE 3000

COPY ./start.sh /tmp/
RUN chmod +x /tmp/start.sh
CMD /tmp/start.sh
