#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

CERT_NAME=$1
EASY_RSA=/usr/share/easy-rsa
OPENVPN_DIR=/etc/openvpn
INDEX=$EASY_RSA/pki/index.txt
OVPN_FILE_PATH="$OPENVPN_DIR/clients/$CERT_NAME.ovpn"

# Check if the OpenVPN configuration file exists
if [[ ! -f $OVPN_FILE_PATH ]]; then
    echo "User not found."
    exit 1
fi

# removing the end of the line starting from /name=$NAME for the line that matches the $serial pattern
sed -i'.bak' "s/\/name=${CERT_NAME}\/.*//" $INDEX
echo "index.txt patched"

# Set the EASYRSA_BATCH variable to enable non-interactive mode for easy-rsa
export EASYRSA_BATCH=1 # see https://superuser.com/questions/1331293/easy-rsa-v3-execute-build-ca-and-gen-req-silently

echo 'Revoke certificate...'

# Change to the easy-rsa directory and copy the easy-rsa variables file
cd $EASY_RSA

# Revoke the specified user's certificate
./easyrsa revoke "$CERT_NAME"

# Generate a new CRL
echo 'Create new Create certificate revocation list (CRL)...'
./easyrsa gen-crl

# Make the CRL file readable
chmod +r $EASY_RSA/pki/crl.pem

echo -e 'Done!\nIf you want to disconnect the user please restart the service using docker-compose restart openvpn.'
