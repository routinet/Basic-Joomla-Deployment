# Basic-Joomla-Deployment

Edit the script file to change the default ip.  Modify the template conf file as desired.

Usage: ./build-new-site.sh -d <domain> [-f <file_domain>] [-i <ip>] [-t template_file] [-s]

    -d domain
    Required parameter.  The domain name to which Apache will respond.

    -f file_domain
    An optional identifier to use for files and directories.  Defaults to <domain>.

    -i ip
    The IP to use for Apache's virtual host.  Defaults to 1.2.3.4.

    -t template_file
    Path to virtual host file to use as a template.  Defaults to /etc/apache2/sites-available/joomla.template.conf.

    -s
    If present, a sandbox site will also be created.  The domain and file_domain
    will each receive "sandbox-" as a prefix.

    -r
    Restart Apache after processing.
