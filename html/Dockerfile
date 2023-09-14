# Use a lightweight Linux distribution as the base image
FROM ubuntu:20.04

# Set the timezone to UTC
ENV TZ=UTC

# Use noninteractive mode to prevent timezone configuration prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y openssh-server curl nginx mariadb-server

# Download html template from github
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

# Create an SFTP user and set a password
RUN useradd -m sftpuser && \
    echo "sftpuser:sftppassword" | chpasswd

# Configure SSH to allow SFTP and password authentication
RUN echo "Match User sftpuser" >> /etc/ssh/sshd_config && \
    echo "ChrootDirectory /var/www/html" >> /etc/ssh/sshd_config && \
    echo "ForceCommand internal-sftp" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    
# Create an MySQL user for development
RUN service mysql start && \
    mysql -e "CREATE USER 'myuser'@'%' IDENTIFIED BY 'mypassword';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'%' WITH GRANT OPTION;" && \
    mysql -e "FLUSH PRIVILEGES;"

RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh && \
    chmod +x ./dotnet-install.sh && \
    ./dotnet-install.sh --channel 7.0

# Start SSH, MariaDB, and Nginx using service
CMD service ssh start && service mysql start && service nginx start && tail -f /dev/null