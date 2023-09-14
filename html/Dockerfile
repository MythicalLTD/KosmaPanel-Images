# Use a lightweight Linux distribution as the base image
FROM ubuntu:20.04

# Set the timezone to UTC
ENV TZ=UTC

# Use noninteractive mode to prevent timezone configuration prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y openssh-server curl nginx mariadb-server git runit sudo nano htop neofetch software-properties-common apt-transport-https ca-certificates gnupg certbot tar unzip zip

# Download html template from GitHub
RUN cd /var/www/html && \
    curl -o index.html https://raw.githubusercontent.com/MythicalLTD/KosmaPanel-Daemon/main/templates/index.html

# Expose the specified ports
EXPOSE 22
EXPOSE 80
EXPOSE 3306
EXPOSE 99

# Allow MariaDB to be accessed from any IP address
RUN sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Install OpenSSH SFTP server
RUN apt-get install -y openssh-sftp-server

# Create an SSH user and set a password (replace "sshuser" and "sshpassword" with your desired username and password)
RUN useradd -m sftpuser && \
    echo "sftpuser:sftppassword" | chpasswd

# Configure SSH to allow password authentication
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Clone the repository
RUN cd /etc && \
    git clone https://github.com/MythicalLTD/KosmaPanel-Daemon.git KosmaPanel && \
    cd /etc/KosmaPanel

# Start KosmaPanel configuration
RUN cd /etc/KosmaPanel/webmanager && \
    bash arch.bash && \ 
    ./KosmaPanelWebManager && \
    ./KosmaPanelWebManager --setHost 0.0.0.0 && \
    ./KosmaPanelWebManager --setPort 99 && \
    ./KosmaPanelWebManager --setKey webmanagerkey && \
    ./KosmaPanelWebManager --setSshPort 22 && \
    ./KosmaPanelWebManager --setSshHost 127.0.0.1 && \
    ./KosmaPanelWebManager --setSshUsername sftpuser && \
    ./KosmaPanelWebManager --setSshPassword sftppassword; 

# Create a Runit service directory for your "webmanager" service
RUN mkdir -p /etc/sv/webmanager

# Create the "webmanager" Runit `run` script
RUN echo '#!/bin/sh' > /etc/sv/webmanager/run && \
    echo 'cd /etc/KosmaPanel/webmanager && ./KosmaPanelWebManager' >> /etc/sv/webmanager/run && \
    chmod +x /etc/sv/webmanager/run

# Create sudoers file to allow passwordless sudo for sftpuser
RUN echo "sftpuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sftpuser

# Start Runit as the init system
CMD service ssh start && service mysql start && service nginx start && tail -f /dev/null && exec runsvdir -P /etc/sv