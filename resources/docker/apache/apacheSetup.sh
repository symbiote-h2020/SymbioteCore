#!/bin/bash
#Install apache
apt-get update
apt-get install -y apache2 telnet iputils-ping git

HOSTNAME_WILDCARD="\[\[docker.hostname\]\]"
HOSTNAME=`grep hostname /home/config.txt | cut -d"=" -f 2`

#Move certificates to apropriate place
mkdir /etc/certs
mv /home/configuration/*.pem /etc/certs

#Enable desired apache mods
rm /etc/apache2/mods-enabled/*
MODS=(access_compat.load alias.conf alias.load auth_basic.load authn_core.load authn_file.load authz_core.load authz_host.load authz_user.load autoindex.conf autoindex.load cgi.load deflate.conf deflate.load dir.conf dir.load env.load filter.load headers.load mime.conf mime.load mpm_event.conf mpm_event.load negotiation.conf negotiation.load proxy.conf proxy_connect.load proxy_html.conf proxy_html.load proxy_http.load proxy.load rewrite.load setenvif.conf setenvif.load socache_shmcb.load ssl.conf ssl.load status.conf status.load xml2enc.load)
for MOD in ${MODS[*]}
do
	ln -s /etc/apache2/mods-available/$MOD /etc/apache2/mods-enabled
done

sed -i "s/$HOSTNAME_WILDCARD/$HOSTNAME/g" /home/configuration/symbiote-https.conf 

#Enable desired symbiote sites
mv /home/configuration/*.conf /etc/apache2/sites-available
rm /etc/apache2/sites-enabled/*
ln -s /etc/apache2/sites-available/symbiote-http.conf /etc/apache2/sites-enabled
ln -s /etc/apache2/sites-available/symbiote-https.conf /etc/apache2/sites-enabled


#Create a blank home page
rm -r /var/www/html
echo "<html></html>" > /var/www/index.html

git clone https://github.com/symbiote-h2020/Demo.git
ln -s /home/Demo/ /var/www/symbioteSearch

sed -i "s/$HOSTNAME_WILDCARD/$HOSTNAME/g" /home/configuration/app.js
cp /home/configuration/app.js /home/Demo/assets/js 

rm -r /home/configuration
