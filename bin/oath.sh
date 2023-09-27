#!/bin/sh
# v.0.1 by @d3vilh@github.com aka Mr. Philipp
# d3vilh/openvpn-server drafted 2FA support
#
# MFA verification by OpenVPN server using oath-tool

# Password file passed by openvpn-server with "auth-user-pass-verify /opt/app/bin/oath.sh via-file" in server.conf
PASSFILE=$1

OPENVPN_DIR=/etc/openvpn
OATH_SECRETS=$OPENVPN_DIR/clients/oath.secrets

# Geting user and password from passed by OpenVPN server tmp file
user=$(head -1 $PASSFILE)
pass=$(tail -1 $PASSFILE) 

# Parsing oath.secrets to getting secret entry, ignore case
secret=$(grep -i -m 1 "$user:" $OATH_SECRETS | cut -d: -f2)

# Getting 2FA code with oathtool based on our secret, exiting with 0 if match:
code=$(oathtool --totp $secret)

if [ "$code" = "$pass" ];
then
	exit 0
fi

# See if we have password and MFA, or just MFA

echo "$pass" | grep -q -i :

if [ $? -eq 0 ];
then
	realpass=$(echo "$pass" | cut -d: -f1)
	mfatoken=$(echo "$pass" | cut -d: -f2)

	# put code here to verify $realpass, the code below the if validates $mfatoken or $pass if false
	# exit 0 if the password is correct, the exit below will deny access otherwise
fi

# If we make it here, auth hasn't succeeded, don't grant access
exit 1
