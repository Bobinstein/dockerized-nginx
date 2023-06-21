#!/bin/sh

# Start Nginx in the background
nginx

# Run the init-letsencrypt.sh script
/usr/local/bin/init-letsencrypt.sh $EMAIL $DOMAIN

# Stop the background Nginx process
nginx -s stop

# Give it a moment to fully stop
sleep 5

# Start Nginx in the foreground
nginx -g 'daemon off;'
