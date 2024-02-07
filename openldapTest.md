## RHEL
openldap-servers openldap-clients openssl
/etc/openldap
user = ldap

## SLES
openldap2 openldap2-client openssl
/etc/openldap
systemctl stop slapd
mv /etc/openldap/slapd.conf /etc/openldap/slapd.conf.backup
mkdir /run/slapd
chown -R 775 /run/slapd
chown -R ldap /run/slapd
slaptest -f /etc/openldap/slapd.conf.olctemplate -F /etc/openldap/slapd.d
mv /usr/lib/openldap/start /usr/lib/openldap/start.backup
echo '#!/bin/sh' > /usr/lib/openldap/start
echo '/usr/sbin/slapd -u ldap -h "ldap:/// ldaps:/// ldapi:///"' >> /usr/lib/openldap/start
chmod 775 /usr/lib/openldap/start
chown ldap /usr/lib/openldap/start
sed -i '/olcAccess:.*/c\olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break' /etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif
chmod -R 700 /etc/openldap/slapd.d
chown -R ldap /etc/openldap/slapd.d
systemctl start slapd
user = ldap

## UBUNTU
lapd ldap-utils openssl
/etc/ldap
user = openldap