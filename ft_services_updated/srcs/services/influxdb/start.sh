#!/bin/sh

influxd run -config /etc/influxdb.conf
# run = run node with existing configuration
# -config = will create a simple InfluxDB configuration file on the chosen path
