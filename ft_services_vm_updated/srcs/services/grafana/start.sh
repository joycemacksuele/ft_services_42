#!/bin/sh

rm /grafana-7.3.5.linux-amd64.tar.gz

# The installation was made from a  binary .tar.gz file, so you need to execute
# the binary (not systemd or init.d) to tart the server
cd /grafana-7.3.5/bin/ && ./grafana-server
