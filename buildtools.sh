#!/bin/bash

# Copyright 2021 Callum McLoughlin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this 
# software and associated documentation files (the "Software"), to deal in the Software 
# without restriction, including without limitation the rights to use, copy, modify, 
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject to the following 
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies 
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS 
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Git Bash Compatibility
MSYS_NO_PATHCONV=0
export MSYS_NO_PATHCONV


echo "### BuildTools ###"
echo "### Version 1.0.0 ###"


## Dependency Check
if ! [ -x "$(command -v docker-compose)" ]
then
  echo "Error: BuildTools requires docker-compose to be installed" >&2
  exit 1
fi

if ! [ -x "$(command -v openssl)" ] 
then
  echo "Error: BuildTools requires OpenSSL to be installed" >&2
  exit 1
fi

if ! [ -x "$(command -v vue)" ] 
then
  echo "Error: BuildTools requires Vue to be installed" >&2
  exit 1
fi


## Default Configuration
VUE_FOLDER="frontend"
NGINX_FOLDER="./nginx"
NGINX_TEMPLATE="nginx.template.conf"
DATA_PATH="./data/letsencrypt"
mkdir -p "$DATA_PATH/conf"

## Create Vue app
if [ ! -d "./$VUE_FOLDER" ] 
then
  vue create frontend --no-git
fi


## User Specified Configuration
CORRECT="n"
while [[ "$CORRECT" != "y" ]]
do
    echo "### Configuration ###"
    read -p "Website URL [example.com]: " WEBSITE_URL
    WEBSITE_URL=${WEBSITE_URL:-"example.com"}

    read -p "email []: " EMAIL

    read -p "RSA Key Size [4096]: " RSA_SIZE
    RSA_SIZE=${RSA_SIZE:-4096}

    read -p "Dry Run? y/n [y]: " STAGING
    STAGING=${STAGING:-y}

    echo
    echo "### Config ###"
    echo "Website: $WEBSITE_URL"
    echo "Email: $EMAIL"
    echo "RSA Key Size: $RSA_SIZE"
    if [ $STAGING != "n" ]
    then 
      echo "Dry Run: Yes"
    else
      echo "Dry Run: No"
    fi
    echo

    read -p "Are the above details correct? y/n: " CORRECT
done


## Create nginx Configuration
export WEBSITE_URL
export DOLLAR='$'
envsubst < "$NGINX_FOLDER/$NGINX_TEMPLATE" > "$NGINX_FOLDER/nginx.conf"


## Download TLS Parameters
if [ ! -e "$DATA_PATH/conf/options-ssl-nginx.conf" ] || [ ! -e "$DATA_PATH/conf/ssl-dhparams.pem" ]
then
  echo "### Downloading TLS Parameters ###"

  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$DATA_PATH/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$DATA_PATH/conf/ssl-dhparams.pem"

  echo "DONE"
fi


### Self Signed Certificates for nginx initial startup
echo "### Generating Self Signed Certificate ###"

CERT_PATH="$DATA_PATH/conf/live/$WEBSITE_URL"
mkdir -p $CERT_PATH

openssl req -x509 -nodes -newkey rsa:$RSA_SIZE -days 1\
  -keyout "$CERT_PATH/privkey.pem" \
  -out "$CERT_PATH/fullchain.pem" \
  -subj "/CN=localhost"
echo


## Docker Startup
echo "### Starting up Certbot ###"
docker-compose up -d certbot

echo "### Starting up nginx ###"
docker-compose up --force-recreate -d nginx


## Remove Self Signed Certs for Certbot
echo "### Deleting Self Signed Certificates ###"
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$WEBSITE_URL && \
  rm -Rf /etc/letsencrypt/archive/$WEBSITE_URL && \
  rm -Rf /etc/letsencrypt/renewal/$WEBSITE_URL.conf" certbot
echo


echo "### Requesting Let's Encrypt Certificate ###"
DOMAIN_ARGUMENT="-d $WEBSITE_URL -d www.$WEBSITE_URL"

if [[ "$EMAIL" != "" ]]
then
  EMAIL_ARGUMENT="--email $EMAIL"
else
  EMAIL_ARGUMENT="--register-unsafely-without-email"
fi

if [ $STAGING != "n" ]
then 
  STAGING_ARGUMENT="--staging"
fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $STAGING_ARGUMENT $EMAIL_ARGUMENT $DOMAIN_ARGUMENT \
    --rsa-key-size $RSA_SIZE --agree-tos --force-renewal" certbot
echo


echo "### Reloading nginx ###"
docker-compose exec nginx nginx -s reload


echo "### Stopping Docker Containers ###"
docker-compose down

echo
echo "### DONE ###"
echo "Press any key to exit..."
read