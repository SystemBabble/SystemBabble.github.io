# FreeRADIUS 3.x EAP-TLS 802.1x on OpenBSD 6.5, 6.6, 6.7

FreeRADIUS is very powerful and can do many different things.
This article is just going to focus on getting an OpenBSD 802.1x EAP-TLS RADIUS server going.
With the goal of serving a wireless WPA2-Enterprise zone.

EAP-TLS is mandated in the WPA2-802.1x standard so every client will support this mode.
It is also one of the most secure of the EAP authentication methods.

## Installation notes

#### Certificate Makefile

OpenBSD FreeRADIUS depends on gmake to run the Makefile in /etc/raddb/certs

The default Makefile needs modifications to get p12 certificates for mobile use, and to generate a CRL.

*Makefile Modifications:*

Under client.pem: client.p12

```
client_android.p12: client.crt
        $(OPENSSL) pkcs12 -export -in client.crt -inkey client.key -certfile ca.pem -name $(USER_NAME) -out client_android.p12 -passin pass:$(PASSWORD_CLIENT)
 -passout pass:$(PASSWORD_CLIENT)
        cp client_android.p12 $(USER_NAME)_android.p12
```

Under ca.der: ca.pem

```
ca.crl: crl_timestamp
        $(OPENSSL) ca -gencrl -keyfile ./ca.key -cert ./ca.pem -out ./ca.crl -config ./ca.cnf -passin pass:$(PASSWORD_CA)
```

To use the crl function in the modified Makefile `crl_timestamp` needs to be created in `/etc/raddb/certs/`
Doing a `$ touch crl_timestamp` tells make to generate a new crl next time gmake is run.

iPhones like the CA cert in .crt form. Convert the ca.pem to .crt like this.

```
openssl x509 -outform der -in your-cert.pem -out your-cert.crt
```

#### TLS Session Resumption

Session caching can be turned on in`raddb/mods-enabled/eap`

```
cache {
    enable = yes
    lifetime = 24
	# these next two options are required since 3.0.14
	# OpenSSL internal session cache was disabled
	name = "sysramble EAP"
    # $ mkdir /var/log/radius/tlscache
	# $ chown _freeradius:wheel /var/log/radius/tlscache
	# $ chmod 750 /var/log/radius/tlscache
    persist_dir = "${logdir}/tlscache"
}
```

A very simple script to keep the CRL updated, and a modified Makefile for use with it is below.

* [crl.sh](./files/crl.sh)
* /etc/raddb/certs/[Makefile](./files/etc/raddb/certs/Makefile)

#### A note about CRL

If you are getting SSL errors about 'CA not found' etc. when CA path seems set correctly etc.

Check crl is up to date.

*To create a certificate revocation list:*

Concatenate crl and ca file into ca_and_crl.pem and set the `ca_file = ${cadir}/ca_and_crl.pem` option in `/etc/raddb/mods-enabled/eap`
Use [crl.sh](./files/crl.sh) and crontab, or another method to keep the `ca_and_crl.pem` file updated.



OR

Set `check_crl = no` in `/etc/raddb/mods-enabled/eap` (not recommended)

#### Elliptic Curves

iOS 9.5.6 does not work with the server.pem or client.pem file being elliptic. But the CA may be an EC cert.

Modern Android does not like any of the certs(CA, Server, Client) being elliptic.

RSA seems to be the only well supported option.

~~A custom Makefile that has been modified to use ecdsa elliptic curves is below.
The certificates that it produces are not very compatible.~~ TODO lost it somwhere find
	
Elliptic Curve: ~~/etc/raddb/certs/Makefile~~

## Config Files

WPA2-802.1x FreeRADIUS example configuration

* /etc/raddb/[radiusd.conf](./files/etc/raddb/radiusd.conf)
* /etc/raddb/[clients.conf](./files/etc/raddb/clients.conf)
* /etc/raddb/[users](./files/etc/raddb/users)
* /etc/raddb/sites-enabled/[default](./files/etc/raddb/sites-enabled/default)
* /etc/raddb/sites-enabled/[check-eap-tls](./files/etc/raddb/sites-enabled/check-eap-tls)
* /etc/raddb/mods-enabled/[eap](./files/etc/raddb/mods-enabled/eap)

Optional helper files

* /etc/raddb/certs/[Makefile](./files/etc/raddb/certs/Makefile)
* [crl.sh](./files/crl.sh)

## Reading
https://wiki.alpinelinux.org/wiki/FreeRadius_EAP-TLS_configuration
https://www.ossramblings.com/RADIUS-3.X-Server-on-Ubuntu-14.04-for-WIFI-Auth

