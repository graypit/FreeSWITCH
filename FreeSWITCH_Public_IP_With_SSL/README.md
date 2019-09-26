### In this README I'll show you how to Generate Certificate with LetsEncrypt for FreeSWITCH and Configure FreeSWITCH to Public Access

#### Prepare your System (It was tested in **Debian 9**):
- Configure Nginx for your Domain-Name (e.g call.graypit.com)
Here is Nginx Configuration Template for **call.graypit.com** (P.S Before Certificating):
```bash
$ cat <<EOF > /etc/nginx/conf.d/call.graypit.com.conf
server {
    server_tokens off;
    server_name call.graypit.com;
    root /var/www/public_html/call.graypit.com/;
    ## Disable .htaccess and other hidden files
    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        log_not_found off;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
    }
    error_log /var/log/nginx/call.graypit.com.error.log;
    access_log /var/log/nginx/call.graypit.com.access.log;

}
EOF
```
#### For Certificates you need :

- Install Certboot (LetsEncrypt Manager) 
- Generate Certificate
- Check Nginx
- Preparing generated certs for FreeSWITCH

Don't Worry... I've written Bash script for that.You need just know your - Domain-Name (e.g call.graypit.com)

Example:
```bash
$ ./fs_letsencrypt_to_fs.sh call.graypit.com
```
And After you need in **/etc/freeswitch/vars.conf** change IP Address to your public and set your Domain-Name :
```xml
  <X-PRE-PROCESS cmd="set" data="local_ip_v4=85.111.233.44"/>
  <X-PRE-PROCESS cmd="set" data="domain=call.graypit.com"/>
  <X-PRE-PROCESS cmd="set" data="domain_name=$${domain}"/>
```

### Enjoy !

