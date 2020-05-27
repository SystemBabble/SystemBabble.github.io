#!/bin/sh

cd /etc/raddb/certs
# update crl_timestamp for Makefile
touch crl_timestamp &&
/usr/local/bin/gmake ca.crl &&
# concatenate ca and crl for freeradius
cat /etc/raddb/certs/ca.pem /etc/raddb/certs/ca.crl > /etc/raddb/certs/ca_and_crl.pem &&
# copy crl to publishing spot
cp ca.crl /var/www/htdocs/freeradius.crl &&
chmod 644 /var/www/htdocs/freeradius.crl

