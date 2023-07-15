# Use the official image as a parent image
FROM nginx:latest

# Copy the Nginx configuration file
COPY nginx/init.conf /etc/nginx/conf.d/default.conf

# Copy the Let's Encrypt initialization script
COPY init-letsencrypt.sh /usr/local/bin/init-letsencrypt.sh

# Copy the Nginx configuration template
COPY nginx/app.conf.template /app/data/nginx/app.conf.template

# Install certbot for SSL certificates generation and cron for scheduling
RUN apt-get update && \
    apt-get install -y \
    certbot \
    python3-certbot-nginx \
    openssl \
    gettext-base \
    cron

# Set necessary permissions for the initialization script
RUN chmod +x /usr/local/bin/init-letsencrypt.sh

RUN mkdir -p /var/www/certbot
RUN chmod -R 777 /var/www/certbot
RUN chown -R www-data:www-data /var/www/certbot

ARG DOMAIN
ARG EMAIL

# Copy the script into the image
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Copy the renew script and crontab file to the appropriate locations
COPY renew-certificates.sh /etc/cron.daily/renew-certificates
RUN chmod +x /etc/cron.daily/renew-certificates
RUN (crontab -l ; echo "0 0 */20 * * /etc/cron.daily/renew-certificates >> /var/log/cron.log 2>&1") | crontab

# Run cron in the background and start the service
CMD cron && /start.sh
