# Use a lightweight Linux distribution as the base image
FROM ubuntu:20.04

# Set the timezone to UTC
ENV TZ=UTC

# Use noninteractive mode to prevent timezone configuration prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y openssh-server curl nginx mariadb-server git runit sudo

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

# Install dotnet
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh && \
    chmod +x ./dotnet-install.sh && \
    ./dotnet-install.sh --channel 7.0 && \
    export DOTNET_ROOT=$HOME/.dotnet && \
    export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools 

RUN echo 'export DOTNET_ROOT=$HOME/.dotnet' >> /root/.bashrc && \
    echo 'export PATH=$PATH:$DOTNET_ROOT' >> /root/.bashrc

# Add dotnet path to sftpuser's .bashrc
USER sftpuser
RUN echo 'export DOTNET_ROOT=$HOME/.dotnet' >> /home/sftpuser/.bashrc && \
    echo 'export PATH=$PATH:$DOTNET_ROOT' >> /home/sftpuser/.bashrc
USER root

# Clone the repository
RUN cd /etc && \
    git clone https://github.com/MythicalLTD/KosmaPanel-Daemon.git KosmaPanel && \
    mv /etc/KosmaPanel/webmanager/webmanager.service /etc/systemd/system/

# Start KosmaPanel configuration
RUN export DOTNET_ROOT=$HOME/.dotnet && \
    export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools && \
    cd /etc/KosmaPanel/webmanager/ && \
    dotnet run --project /etc/KosmaPanel/webmanager --setPort 99 && \
    dotnet run --project /etc/KosmaPanel/webmanager --setKey webmanagerkey && \
    dotnet run --project /etc/KosmaPanel/webmanager --setSshPort 22 && \
    dotnet run --project /etc/KosmaPanel/webmanager --setSshHost 127.0.0.1 && \
    dotnet run --project /etc/KosmaPanel/webmanager --setSshUsername sftpuser && \
    dotnet run --project /etc/KosmaPanel/webmanager --setSshPassword sftppassword

# Create a Runit service directory for your "webmanager" service
RUN mkdir -p /etc/sv/webmanager

# Create the "webmanager" Runit `run` script
RUN echo '#!/bin/sh' > /etc/sv/webmanager/run && \
    echo 'export DOTNET_ROOT=$HOME/.dotnet &&  export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools && dotnet run --project /etc/KosmaPanel/webmanager' >> /etc/sv/webmanager/run && \
    chmod +x /etc/sv/webmanager/run

# Create sudoers file to allow passwordless sudo for sftpuser
RUN echo "sftpuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sftpuser

# Start Runit as the init system
CMD service ssh start && service mysql start && service nginx start && tail -f /dev/null && exec runsvdir -P /etc/sv