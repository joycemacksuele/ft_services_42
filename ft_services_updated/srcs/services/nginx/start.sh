#!/bin/sh

/usr/sbin/sshd
# sshd (OpenSSH Daemon) is the daemon program for ssh
# Together these programs replace rlogin and rsh, and provide secure
# encrypted communications between two untrusted hosts over an insecure network

/usr/sbin/nginx -g 'daemon off;'
# For normal production (on a server), use the default 'daemon on;'
# In this case for Docker containers (or for debugging), use the 'daemon off;'
