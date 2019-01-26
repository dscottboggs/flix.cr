#!/bin/bash

set -euxo pipefail

ssl_email=""
ssl_domain=""
prod_mode=""
cert_dir='/etc/letsencrypt'
insecure=""

args2fwd=""

puts_help() {
  [ $1 ] && echo $1
  cat << HERE
local-deploy.sh: deploy a flix.cr instance with letsencrypt generated SSL certificates

WARNING: this script assumes you have ports 80 and 443 open to the machine running
the script, and a valid domain pointed at your IP. Since it's easy to mess this up
and LetsEncrypt has such strict rate limits, by default, this script generates "fake"
LetsEncrypt certificates, which are not valid but demonstrate the success of the
process of generating the certificate. Once you have obtained a valid "fake"
certificate, run the script again in --production mode to get a real cert.

Usage:
    sudo ./local-deploy.sh --ssl-email EMAIL --ssl-domain DOMAIN [--production --no-extra-security --cert-dir DIRECTORY]

  --ssl-email             the email to send letsencrypt notifications to
  --ssl-domain            the domain to certify and deploy
  --production            uses a real (production) certificate with strict rate limits
  --cert-dir              where to put the letsencrypt configurations (default $cert_dir)
  --no-extra-security     Turns off the default extra security options:
                            - Bigger RSA key size
                            - OCSP stapling
                            - HSTS
HERE
  exit
}

build_flix() {
  crystal build -o/usr/local/bin/flix --release --progress src/flix.cr
}

which certbot || puts_help 'certbot must be installed and on your $PATH!'
which flix || build_flix

#parse CLI arguments
while (( "$#" )); do
  case $1 in
    -e|--ssl-email) ssl_email=$2; shift;;
    -d|--ssl-domain) ssl_domain=$2; shift;;
    -h|--help) puts_help;;
    --production) prod_mode=true;;
    --cert-dir) cert_dir=$2; shift;;
    --no-extra-security) insecure=true;;
    *) args2fwd="$args2fwd $1";;
  esac
  shift
done

# default/production certbot options
cert_opts="certonly --standalone --agree-tos --email $ssl_email -n"
cert_opts="$cert_opts --domain $ssl_domain --keep-until-expiring"
cert_opts="$cert_opts --config-dir $cert_dir"

# add optional arguments to the command
if [ "$prod_mode" = "" ]; then
  # staging cert
  cert_opts="$cert_opts --staging"
elif [ "$insecure" = "" ]; then
  # extra security options -- only bother when not doing staging
  cert_opts="$cert_opts --staple-ocsp --hsts --rsa-key-size 4096"
fi

# execute
certbot $cert_opts

flix $args2fwd \
  --key-file ${cert_dir}/live/${ssl_domain}/privkey.pem \
  --cert-file ${cert_dir}/live/${ssl_domain}/fullchain.pem
