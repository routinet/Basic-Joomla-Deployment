#!/bin/bash

default_ip=127.0.0.1

usage() {
    echo "
Usage: $0 -d <domain> [-f <file_domain>] [-i <ip>] [-t template_file] [-s]

    -d domain 
    Required parameter.  The domain name to which Apache will respond.

    -f file_domain 
    An optional identifier to use for files and directories.  Defaults to <domain>.

    -i ip
    The IP to use for Apache's virtual host.  Defaults to $default_ip.

    -t template_file
    Path to virtual host file to use as a template.  Defaults to /etc/apache2/sites-available/joomla.template.conf.

    -s
    If present, a sandbox site will also be created.  The domain and file_domain
    will each receive \"sandbox-\" as a prefix.

    -r 
    Restart Apache after processing.
" >&2
}

template_file=/etc/apache2/sites-available/joomla.template.conf
ip=$default_ip
restart_apache=0

# read in the command line config
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    -d) shift; domain=$1 ;;
    -f) shift; file_domain=$1 ;;
    -i) shift; ip=$1;;
    -t) shift; template_file=$1 ;;
    -r) restart_apache=1 ;;
    -s) sandbox=1 ;;
    *) echo "$0: $1: Ignoring invalid option" >&2 ;;
  esac
  shift
done

if [[ "$domain" == "" ]]
then
    echo Did not find expected -d parameter.
    usage
    exit 1
fi 

if [[ "$file_domain" == "" ]]
then
    file_domain=$domain
fi

dl_url=`curl -s https://api.github.com/repos/joomla/joomla-cms/releases/latest | python -c "import json,sys;obj=json.load(sys.stdin);print '\\n'.join([x['browser_download_url'] for x in obj['assets']]);" | grep 'Stable-Full_Package.tar.gz'`
conf_file=/etc/apache2/sites-available/${file_domain}.conf
package_file=$(basename $dl_url)

echo "
Using:
   domain: $domain
   filename identifier: $file_domain
   ip address: $ip
   template file: $template_file
   conf file: $conf_file
   download: $dl_url
   package: $package_file
"

curdir=$PWD

if [ -d "/var/www/$file_domain" ] 
then
    echo "Found /var/www/$file_domain already exists; exiting."
    exit 2
fi

if [ ! -f ${template_file} ]
then
    echo "Could not locate template file: $template_file"
    exit 3
fi

cat $template_file | sed -e "s/@domain@/$domain/g" | sed -e "s/@file_domain@/$file_domain/g" | sed -e "s/@ip@/$ip/g" > $conf_file
if [[ "$sandbox" -eq "1" ]]
then
    sed -i -e "s/^#//g" $conf_file
fi

mkdir "/var/www/$file_domain"
cd "/var/www/$file_domain"
wget $dl_url
tar xzf $package_file
rm $package_file
chown -R www-data:www-data "/var/www/$file_domain"
chmod -R g+w "/var/www/$file_domain"

if [[ "$sandbox" -eq "1" ]]
then
    cp -r /var/www/$file_domain /var/www/sandbox-${file_domain}
    chown www-data:www-data /var/www/sandbox-${file_domain}
    chmod g+w /var/www/sandbox-${file_domain}
fi

cd $curdir

a2ensite `basename $conf_file`
if [[ "$restart_apache" -eq "1" ]]
then
    service apache2 restart
fi
