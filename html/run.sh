docker run -d -p 2222:22 -p 8000:80 -p 9999:99 -p 3333:3306 \
  -e SFTP_USER=mycustomuser \
  -e SFTP_PASSWORD=mycustompassword \
  -e WEBMANAGER_KEY=daddy \
  --name kosmapanel_html \
  --memory 512m \
  --cpus 0.5 \
  --volume web_data:/var/www/html \
  --restart unless-stopped \
  kosmapanel:html
