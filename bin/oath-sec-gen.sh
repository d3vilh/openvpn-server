#!/bin/sh
# v.0.1 by @d3vilh@github.com aka Mr. Philipp
# d3vilh/openvpn-server drafted 2FA support

# Client name in format: alice@wonderland.us
TFA_NAME=$1
OPENVPN_DIR=/etc/openvpn
OATH_SECRETS=$OPENVPN_DIR/clients/oath.secrets

# Issuer string
ISSUER='MFA%20OpenVPN'

# Userhash. Random 30 chars
USERHASH=$(head -c 10 /dev/urandom | openssl sha256 | cut -d ' ' -f2 | cut -b 1-30)

# Base32 secret from oathtool output
BASE32=$(/usr/bin/oathtool --totp -v "$USERHASH" | grep Base32 | awk '{print $3}')

# QR code for user to pass to Google Authenticator or OpenVPN-UI
echo "User String for QR:"
echo "otpauth://totp/$ISSUER:$TFA_NAME?secret=$BASE32"

# New string for secrets file
echo "oath.secrets entry for BackEnd:"
echo "$TFA_NAME:$USERHASH" | tee -a $OATH_SECRETS
