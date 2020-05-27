######################################################################
#
#	Make file to be installed in /etc/raddb/certs to enable
#	the easy creation of certificates.
#
#	See the README file in this directory for more information.
#
#	$Id: 16447a023d2cdce2d16d39cf31bcde4dba600df5 $
#
######################################################################

DH_KEY_SIZE	= 4096
OPENSSL		= openssl
EXTERNAL_CA	= $(wildcard external_ca.*)

ifneq "$(EXTERNAL_CA)" ""
PARTIAL		= -partial_chain
endif

#
#  Set the passwords
#
PASSWORD_SERVER!=	grep output_password server.cnf | sed 's/.*=//;s/^ *//'
PASSWORD_INNER!=	grep output_password inner-server.cnf | sed 's/.*=//;s/^ *//'
PASSWORD_CA!=		grep output_password ca.cnf | sed 's/.*=//;s/^ *//'
PASSWORD_CLIENT!=	grep output_password client.cnf | sed 's/.*=//;s/^ *//'
USER_NAME!=		grep emailAddress client.cnf | grep '@' | sed 's/.*=//;s/^ *//'
CA_DEFAULT_DAYS!=	grep default_days ca.cnf | sed 's/.*=//;s/^ *//'

######################################################################
#
#  Make the necessary files, but not client certificates.
#
######################################################################
.PHONY: all
all: index.txt serial dh server ca client

.PHONY: client
client: client.pem

.PHONY: ca
ca: ca.der

.PHONY: server
server: server.pem server.vrfy

.PHONY: inner-server
inner-server: inner-server.pem inner-server.vrfy

.PHONY: verify
verify: server.vrfy client.vrfy

######################################################################
#
#  Diffie-Hellman parameters
#
######################################################################
dh:
	$(OPENSSL) dhparam -out dh -2 $(DH_KEY_SIZE)

######################################################################
#
#  Create a new self-signed CA certificate
#
######################################################################
ca.key ca.pem: ca.cnf
	@[ -f index.txt ] || $(MAKE) index.txt
	@[ -f serial ] || $(MAKE) serial
	$(OPENSSL) req -new -x509 -keyout ca.key -out ca.pem \
		-days $(CA_DEFAULT_DAYS) -config ./ca.cnf
	chmod g+r ca.key

ca.der: ca.pem
	$(OPENSSL) x509 -inform PEM -outform DER -in ca.pem -out ca.der

ca.crl: crl_timestamp
	$(OPENSSL) ca -gencrl -keyfile ./ca.key -cert ./ca.pem -out ./ca.crl -config ./ca.cnf -passin pass:$(PASSWORD_CA)

ca.crt: ca.pem
	$(OPENSSL) x509 -outform der -in ca.pem -out ca.crt

######################################################################
#
#  Create a new server certificate, signed by the above CA.
#
######################################################################
server.csr server.key: server.cnf
	$(OPENSSL) req -new  -out server.csr -keyout server.key -config ./server.cnf
	chmod g+r server.key

server.crt: server.csr ca.key ca.pem
	$(OPENSSL) ca -batch -keyfile ca.key -cert ca.pem -in server.csr  -key $(PASSWORD_CA) -out server.crt -extensions xpserver_ext -extfile xpextensions -config ./server.cnf

server.p12: server.crt
	$(OPENSSL) pkcs12 -export -in server.crt -inkey server.key -out server.p12  -passin pass:$(PASSWORD_SERVER) -passout pass:$(PASSWORD_SERVER)
	chmod g+r server.p12

server.pem: server.p12
	$(OPENSSL) pkcs12 -in server.p12 -out server.pem -passin pass:$(PASSWORD_SERVER) -passout pass:$(PASSWORD_SERVER)
	chmod g+r server.pem

.PHONY: server.vrfy
server.vrfy: ca.pem
	@$(OPENSSL) verify $(PARTIAL) -CAfile ca.pem server.pem

######################################################################
#
#  Create a new client certificate, signed by the the above server
#  certificate.
#
######################################################################
client.csr client.key: client.cnf
	$(OPENSSL) req -new  -out client.csr -keyout client.key -config ./client.cnf
	chmod g+r client.key

client.crt: client.csr ca.pem ca.key
	$(OPENSSL) ca -batch -keyfile ca.key -cert ca.pem -in client.csr  -key $(PASSWORD_CA) -out client.crt -extensions xpclient_ext -extfile xpextensions -config ./client.cnf

client.p12: client.crt
	$(OPENSSL) pkcs12 -export -in client.crt -inkey client.key -out client.p12  -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)
	chmod g+r client.p12

client.pem: client.p12
	$(OPENSSL) pkcs12 -in client.p12 -out client.pem -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)
	chmod g+r client.pem
	cp client.pem $(USER_NAME).pem

client_android.p12: client.pem
	$(OPENSSL) pkcs12 -export -in client.crt -inkey client.key -certfile ca.pem -name $(USER_NAME) -out client_android.p12 -passin pass:$(PASSWORD_CLIENT)	-passout pass:$(PASSWORD_CLIENT)
	cp client_android.p12 $(USER_NAME)_android.p12

.PHONY: client.vrfy
client.vrfy: ca.pem client.pem
	c_rehash .
	$(OPENSSL) verify -CApath . client.pem

######################################################################
#
#  Create a new inner-server certificate, signed by the above CA.
#
######################################################################
inner-server.csr inner-server.key: inner-server.cnf
	$(OPENSSL) req -new  -out inner-server.csr -keyout inner-server.key -config ./inner-server.cnf
	chmod g+r inner-server.key

inner-server.crt: inner-server.csr ca.key ca.pem
	$(OPENSSL) ca -batch -keyfile ca.key -cert ca.pem -in inner-server.csr  -key $(PASSWORD_CA) -out inner-server.crt -extensions xpserver_ext -extfile xpextensions -config ./inner-server.cnf

inner-server.p12: inner-server.crt
	$(OPENSSL) pkcs12 -export -in inner-server.crt -inkey inner-server.key -out inner-server.p12  -passin pass:$(PASSWORD_INNER) -passout pass:$(PASSWORD_INNER)
	chmod g+r inner-server.p12

inner-server.pem: inner-server.p12
	$(OPENSSL) pkcs12 -in inner-server.p12 -out inner-server.pem -passin pass:$(PASSWORD_INNER) -passout pass:$(PASSWORD_INNER)
	chmod g+r inner-server.pem

.PHONY: inner-server.vrfy
inner-server.vrfy: ca.pem
	@$(OPENSSL) verify $(PARTIAL) -CAfile ca.pem inner-server.pem

######################################################################
#
#  Miscellaneous rules.
#
######################################################################
index.txt:
	@touch index.txt

serial:
	@echo '01' > serial

print:
	$(OPENSSL) x509 -text -in server.crt

printca:
	$(OPENSSL) x509 -text -in ca.pem

clean:
	@rm -f *~ *old client.csr client.key client.crt client.p12 client.pem

#
#	Make a target that people won't run too often.
#
destroycerts:
	rm -f *~ dh *.csr *.crt *.p12 *.der *.pem *.key index.txt* \
			serial*  *\.0 *\.1
