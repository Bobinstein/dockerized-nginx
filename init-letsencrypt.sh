#!/bin/bash

# Define the domain and email variables.
domains=($DOMAIN)
email=$EMAIL
staging=0

# Define the URL for the Let's Encrypt directory.
if (( $staging != "0" )); then
  url="https://acme-staging-v02.api.letsencrypt.org/directory"
  echo "Requesting Let's Encrypt certificate for $domains (staging)..."
else
  url="https://acme-v02.api.letsencrypt.org/directory"
  echo "Requesting Let's Encrypt certificate for $domains..."
fi

# Check if a valid, non-expired certificate already exists.
if [ -d "/etc/letsencrypt/live/$domains" ]; then
  echo "Existing certificate for $domains detected, checking expiration date..."

  # Extract the expiration date of the certificate.
  exp=$(openssl x509 -noout -dates -in "/etc/letsencrypt/live/$domains/fullchain.pem" | grep 'notAfter' | cut -d= -f2)
  exp_date=$(date -d"$exp" +%s)
  now=$(date +%s)

  # Check if the certificate has expired.
  if (( $now >= $exp_date )); then
    echo "Certificate for $domains has expired, renewing..."
    renew_cert=1
  else
    echo "Certificate for $domains is valid, skipping certificate request..."
    renew_cert=0
  fi
else
  echo "No existing certificate for $domains detected, requesting new certificate..."
  renew_cert=1
fi

if [[ $renew_cert -eq 1 ]]; then
  # Request the actual certificate
  echo $DOMAIN
  echo $EMAIL

  # The --post-hook option changes the ownership and permissions of the retrieved certificates so that the www-data user can read them.
  certbot certonly --debug -v --webroot --debug-challenges --non-interactive -w /var/www/certbot --agree-tos --force-renewal --cert-name $DOMAIN --server $url --email $EMAIL -d $DOMAIN --post-hook 'chown -R root:www-data /etc/letsencrypt/live /etc/letsencrypt/archive && chmod 750 /etc/letsencrypt/live /etc/letsencrypt/archive'
  if [[ $? -ne 0 ]]; then
    echo "Failed to create real certificate, exiting..."
    exit 1
  fi

  echo "Real certificate created."
fi

echo "Writing new configuration."

envsubst '$DOMAIN' < /app/data/nginx/app.conf.template > /etc/nginx/conf.d/default.conf

# Reload nginx service.
echo "Reloading nginx with new certificate..."
nginx -s reload

if [[ $? -ne 0 ]]; then
  echo "Failed to reload nginx with new certificate, exiting..."
  exit 1
fi

echo "Done!"
