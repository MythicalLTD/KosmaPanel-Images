# Use a lightweight Linux distribution as the base image
FROM ubuntu:20.04

# Set the timezone to UTC
ENV TZ=UTC

# Use noninteractive mode to prevent timezone configuration prompts
ENV DEBIAN_FRONTEND=noninteractive
# Set the ENV for docker
ENV SFTP_USER=${SFTP_USER:-sftpuser}
ENV SFTP_PASSWORD=${SFTP_PASSWORD:-sftppassword}
ENV WEBMANAGER_KEY=${WEBMANAGER_KEY:-1234}

# Install necessary packages
RUN apt update && apt install -y apt-utils openssh-server curl nginx mariadb-server git runit sudo nano htop neofetch software-properties-common apt-transport-https ca-certificates gnupg certbot tar unzip zip openssh-sftp-server

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

# Apply updates
RUN apt upgrade -y

# Create an SSH user and set a password (replace "sshuser" and "sshpassword" with your desired username and password)
RUN useradd -m $SFTP_USER && \
    echo "$SFTP_USER:$SFTP_PASSWORD" | chpasswd

# Configure SSH to allow password authentication
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Clone the repository
RUN cd /etc && \
    git clone https://github.com/MythicalLTD/KosmaPanel-WebManager.git KosmaPanel-WebManager && \
    cd /etc/KosmaPanel-WebManager

# Start KosmaPanel configuration
RUN cd /etc/KosmaPanel-WebManager && \
    bash arch.bash && \ 
    ./KosmaPanel && \
    ./KosmaPanel --setHost 0.0.0.0 && \
    ./KosmaPanel --setPort 99 && \
    ./KosmaPanel --setKey $WEBMANAGER_KEY && \
    ./KosmaPanel --setSshPort 22 && \
    ./KosmaPanel --setSshHost 127.0.0.1 && \
    ./KosmaPanel --setSshUsername $SFTP_USER && \
    ./KosmaPanel --setSshPassword $SFTP_PASSWORD; 

# Create a Runit service directory for your "webmanager" service
RUN mkdir -p /etc/sv/webmanager

# Create the "webmanager" Runit `run` script
RUN echo '#!/bin/sh' > /etc/sv/webmanager/run && \
    echo 'cd /etc/KosmaPanel-WebManager && ./KosmaPanel' >> /etc/sv/webmanager/run && \
    chmod +x /etc/sv/webmanager/run

# Create sudoers file to allow passwordless sudo for sftpuser
RUN echo "$SFTP_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$SFTP_USER

# Start Runit as the init system
CMD service ssh start && service nginx start && service mysql start && cd /etc/KosmaPanel-WebManager && ./KosmaPanel && tail -f /dev/null && exec runsvdir -P /etc/sv