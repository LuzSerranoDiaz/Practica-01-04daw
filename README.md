# Practica-01-04daw

# Creacion de instancia en OpenStack

![instancias](https://github.com/LuzSerranoDiaz/Practica-01-04daw/assets/125549381/67a7ca00-5d03-4675-a7d5-40edebf118f0)

Se crea una instancia de Ubuntu 23.04 con sabor m1.medium para que no haya errores con la memoria ram.

![clave](https://github.com/LuzSerranoDiaz/Practica-01-04daw/assets/125549381/5e9e8f63-3b33-4d32-ac35-c1c5a7c7966a)

Se utiliza el par de claves ya utilizado.

![SecurityGroup](https://github.com/LuzSerranoDiaz/Practica-01-04daw/assets/125549381/6f51a472-64b6-4e71-9a0f-50af0d877de4)

Se añaden excepciones en el grupo de seguridad para los puertos 22(SSH), 80(HTTP) y 443(HTTPS), y ICMP.

# Documento tecnico practica 1 despliegue de aplicaciones web DAW

En este documento se presentará los elementos para instalar LAMP, junto otras herramientas y modificaciones.

## Install_lamp.sh
```bash
#!/bin/bash
 
#Para mostrar los comandos que se van ejecutando
set -ex

#Actualizamos la lista de repositorios
apt update
#Actualizamos los paquetes del sistema
#apt upgrade -y

#Instalamos el servidor APACHE
sudo apt install apache2 -y

#Instalamos MYSQL SERVER
apt install mysql-server -y

#Instalar php 
sudo apt install php libapache2-mod-php php-mysql -y

#Copiamos archivo de configuracion de apache
cp ../conf/000-default.conf /etc/apache2/sites-available

#Reiniciamos servicio apache
systemctl restart apache2

#Copiamos el archivo de prueba de PHP
cp ../php/index.php /var/www/html

#Cambiamos usuario y propietario de var/www/html
chown -R www-data:www-data /var/www/html
```
En este script se realiza la instalación de LAMP en la última version de **ubuntu server** junto con la modificación del archivo 000-default.conf, para que las peticiones que lleguen al puerto 80 sean redirigidas al index encontrado en /var/www/html
### Como ejecutar Install_lamp.sh
1. Abre un terminal
2. Concede permisos de ejecución
 ```bash
 chmod +x install_lamp.sh
 ```
 o
 ```bash
 chmod 755 install_lamp.sh
 ```
 3. Ejecuta el archivo
 ```bash
 sudo ./install_lamp.sh
 ```
## .env 
```bash
OPENSSL_COUNTRY="ES"
OPENSSL_PROVINCE="Almeria"
OPENSSL_LOCALITY="Almeria"
OPENSSL_ORGANIZATION="IES Celia"
OPENSSL_ORGUNIT="Departamento de Informatica"
OPENSSL_COMMON_NAME="practica-https.local"
OPENSSL_EMAIL="admin@iescelia.org"
```

## setup_selfsigned_certificate.sh

```bash
#!/bin/bash
 
# Para mostrar los comandos que se van ejecutando (x) y parar en error(e)
set -ex

# Actualizamos la lista de repositorios
 apt update
# ACtualizamos los paquetes del sistema
# apt upgrade -y

source .env
```
Se realizan los pasos premeditarios:
1. Actualizar repositorios
2. Se importa .env
```bash
#Como autorizar la creación de un certificado autofirmado
openssl req \
  -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt \
  -subj "/C=$OPENSSL_COUNTRY/ST=$OPENSSL_PROVINCE/L=$OPENSSL_LOCALITY/O=$OPENSSL_ORGANIZATION/OU=$OPENSSL_ORGUNIT/CN=$OPENSSL_COMMON_NAME/emailAddress=$OPENSSL_EMAIL"
```
Con el comando openssl creamos un certificado autofirmado:
1. `req` Crea certificados autofirmados, tambien puede ser utilizado para crear solicitudes en el formato `PKCS#10` 
2. `-x509` Indica que queremos crear un certificado autofirmado en vez de una solicitud de certificado
3. `-nodes` Indica que la clave privada del certificado no está protegida por contraseña y sin encriptar
4. `-days 365` Indica la validez del certificado, que será de 365
5. `-newkey rsa:2048` Indica que genere una nueva clave privada de 2048 bits junto al certificado
6. `-keyout /etc/ssl/private/apache-selfsigned.key` Indica la ubicación donde se guardará la clave privada generada
7. `-out /etc/ssl/certs/apache-selfsigned.crt \`  Indica el la ubicacion y nombre del archivo donde se guardara el certificado
8. `-subj` Se utiliza para automatizar la creación del certificacion, se indica el pais, la provincia, la localidad, el nombre de la organización, el nombre de la unidad de la organización, el nombre y el correo electronico

### default-ssl.conf
```
ServerSignature Off
ServerTokens Prod

<VirtualHost *:443>
    #ServerName practica-https.local
    DocumentRoot /var/www/html
    DirectoryIndex index.php index.html

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
</VirtualHost>
```
* `<VirtualHost *:443>` Escuchará el puerto HTTPS
* `ServerName` Indica el nombre del dominio e indica al servidor web APache que peticiones debe servir para este virtual host.
* `DocumentRoot` Donde se encuentra el directorio raiz del host virtual
* `SSLEngine on` Indica que este virtual host utilizará SSL/TLS
* `SSLCertificateFile` Indica la ruta donde se encuentra el certificado autofirmado
* `SSLCertificateKeyFile` Indica la ruta donde se encuentra la clave privada del certificado autofirmado

```bash
#copiamos archivo virtualhost de ssl/tls
cp ../conf/default-ssl.conf /etc/apache2/sites-available

#habilitamos el virtualhost que acabamos de copiar
a2ensite default-ssl.conf

#habilitamos modulo ssl para apache
a2enmod ssl
```
1. Copiamos default-ssl.conf a /apache2/sites-available para ser abilitado
2. Abilitamos el virtualhost utilizando el comando `a2ensite`
3. Abilitamos el modulo para apache2 utilizando `a2enmod`

### 000-default.conf
```
<VirtualHost *:80>
    #ServerName practica-https.local
    DocumentRoot /var/www/html

    # Redirige al puerto 443 (HTTPS)
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
```
* `<VirtualHost *:80>` Escucha el puerto 80 (HTTP)
* `RewriteEngine On` Habilita el motor de reescritura de URLS y nos permite usar reglas de reescritura
* `RewriteCond %{HTTPS} off` Esta directiva es una condición que comprueba si la peticion recibida utiliza HTTPS o no. Si se cumple esta condición entonces se ejecuta la siguiente linea.
* `RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]` Las reglas de reescritura tienen la siguiente sintaxis RewriteRule Pattern Substitution   [flags]
* `Pattern` El patron que se debe cumplir en la URL solicitada para que la regla de reescritura se aplique. En este caso, ^ coincide con el principio de la URL, por lo que se aplicará a todas las solicitudes.
* `Substitution` Es la URL a la que se redirige la solicitud. En este caso, se utiliza el valor https://%{HTTP_HOST}%{REQUEST_URI} y por lo tanto se redirige la solicitud a HTTPS manteniendo el mismo nombre de dominio y URI
* `flags`  Son los flags que se pueden utilizar para modificar el comportamiento de la regla de reescritura. En este caso, el flag [L,R=301] indica que es una redirección permanente (Código de estado: 301).

```bash
#copiamos el archivo de virtualhost de http
cp ../conf/000-default.conf /etc/apache2/sites-available

#habilitamos
a2enmod rewrite

systemctl restart apache2
```
1. Se mueve el archivo de configuración a sites-available a ser habilitado
2. Se habilita el archivo con `a2enmod`
3. Reiniciamos

