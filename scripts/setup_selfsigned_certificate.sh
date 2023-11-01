#!/bin/bash
 
# Para mostrar los comandos que se van ejecutando (x) y parar en error(e)
set -ex

# Actualizamos la lista de repositorios
 apt update
# ACtualizamos los paquetes del sistema
# apt upgrade -y

source .env

#Como autorizar la creación de un certificado autofirmado
openssl req \
  -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt \
  -subj "/C=$OPENSSL_COUNTRY/ST=$OPENSSL_PROVINCE/L=$OPENSSL_LOCALITY/O=$OPENSSL_ORGANIZATION/OU=$OPENSSL_ORGUNIT/CN=$OPENSSL_COMMON_NAME/emailAddress=$OPENSSL_EMAIL"

#copiamos archivo virtualhost de ssl/tls
cp ../conf/default-ssl.conf /etc/apache2/sites-available

#habilitamos el virtualhost que acabamos de copiar
a2ensite default-ssl.conf

#habilitamos modulo ssl para apache
a2enmod ssl

#copiamos el archivo de virtualhost de http
cp ../conf/000-default.conf /etc/apache2/sites-available

#habilitamos
a2enmod rewrite

systemctl restart apache2
