# Use a lightweight Linux distribution as the base image
FROM ubuntu:22.04

# Set the timezone to UTC
ENV TZ=UTC

# Use noninteractive mode to prevent timezone configuration prompts
ENV DEBIAN_FRONTEND=noninteractive
# Set the ENV for docker
ENV USERNAME=test
ENV PASSWORD=1234
ENV WEBMANAGER_KEY=1234
ENV PHP_VERSION=8.1

# Install necessary packages
RUN apt update && apt install -y apt-utils openssh-server curl nginx git runit sudo nano htop neofetch software-properties-common apt-transport-https ca-certificates gnupg certbot tar unzip zip openssh-sftp-server mysql-server
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
# Install PHP and related packages
RUN apt-get update && \
    apt-get install -y php$PHP_VERSION php$PHP_VERSION-common php$PHP_VERSION-cli php$PHP_VERSION-gd php$PHP_VERSION-mysql php$PHP_VERSION-mbstring php$PHP_VERSION-bcmath php$PHP_VERSION-xml php$PHP_VERSION-fpm php$PHP_VERSION-curl php$PHP_VERSION-zip
RUN curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
RUN apt install redis-server -y 
# Download html template from GitHub
RUN mkdir -p /var/www/html/public && \
    mkdir -p /var/www/html/logs && \
    cd /var/www/html/public && \
    curl -o index.php https://raw.githubusercontent.com/MythicalLTD/KosmaPanel-Daemon/main/templates/index.html

# Expose the specified ports
EXPOSE 22
EXPOSE 80
EXPOSE 3306
EXPOSE 99

# Apply updates
RUN apt update && apt upgrade -y

# Create an SSH user and set a password (replace "sshuser" and "sshpassword" with your desired username and password)
RUN useradd -m $USERNAME && \
    echo "$USERNAME:$PASSWORD" | chpasswd

# Configure SSH to allow password authentication
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Clone the repository
RUN cd /etc && \
    git clone https://github.com/MythicalLTD/KosmaPanel-WebManager.git KosmaPanel-WebManager && \
    cd /etc/KosmaPanel-WebManager

RUN cd /etc/nginx/sites-enabled && \
    curl -o default https://raw.githubusercontent.com/MythicalLTD/Assets/main/kosmpanel_php_config_public.conf

# Start KosmaPanel configuration
RUN cd /etc/KosmaPanel-WebManager && \
    bash arch.bash && \ 
    ./KosmaPanel && \
    ./KosmaPanel --setHost 0.0.0.0 && \
    ./KosmaPanel --setPort 99 && \
    ./KosmaPanel --setKey $WEBMANAGER_KEY && \
    ./KosmaPanel --setSshPort 22 && \
    ./KosmaPanel --setSshHost 127.0.0.1 && \
    ./KosmaPanel --setSshUsername $USERNAME && \
    ./KosmaPanel --setSshPassword $PASSWORD; 

# Create a Runit service directory for your "webmanager" service
RUN mkdir -p /etc/sv/webmanager

# Create the "webmanager" Runit `run` script
RUN echo '#!/bin/sh' > /etc/sv/webmanager/run && \
    echo 'cd /etc/KosmaPanel-WebManager && ./KosmaPanel' >> /etc/sv/webmanager/run && \
    chmod +x /etc/sv/webmanager/run

# Create rs file to allow passwordless sudo for sftpuser
RUN echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USERNAME

# Allow mysql to be accessed from any IP address
RUN echo "[mysqld]\nbind-address = '0.0.0.0'" >> /etc/mysql/my.cnf
RUN echo "default_time_zone = '+00:00'" >> /etc/mysql/my.cnf
RUN service mysql start

RUN sudo apt-get update && \
        sudo apt-get install -y dotnet-sdk-7.0 && \
        sudo apt-get install -y dotnet-runtime-7.0

# Start Runit as the init system
CMD service mysql start && service php$PHP_VERSION-fpm start && service ssh start && service nginx start && cd /etc/KosmaPanel-WebManager && ./KosmaPanel && tail -f /dev/null && exec runsvdir -P /etc/sv