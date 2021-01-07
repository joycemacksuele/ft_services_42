FROM alpine:latest

MAINTAINER Joyce Freitas <jfreitas@student.19.fr>

RUN apk update && apk upgrade
RUN apk add vsftpd


#################################### SSL ######################################
RUN apk add openssl
RUN openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out /etc/ssl/certs/vsftpd.pem -keyout /etc/ssl/certs/vsftpd.pem -subj "/C=FR/ST=Paris/L=75017/O=42 school/CN=ft_services"
RUN chmod 600 /etc/ssl/certs/vsftpd.pem


################################ FTP Config ###################################
COPY ./my_vsftpd.conf /etc/vsftpd/vsftpd.conf

RUN mkdir -p /ftps/user
RUN adduser -D user
RUN echo "user:password" | /usr/sbin/chpasswd
# chpasswd: reads a list of user name and password pairs from standard input
# and uses this information to update a group of existing users

RUN chown -R user:user /ftps/user
RUN chmod -R 755 /ftps/user

# Copy a dummy file just so that we can see it during the correction
COPY ./dummy_test.txt /home/user/


EXPOSE 20 21 21000
# Port 21 is used to establish the connection between the 2 computers (or hosts)
# One extra port open (21000) for one data connection

COPY ./start.sh /tmp/
RUN chmod +x /tmp/start.sh
CMD /tmp/start.sh
