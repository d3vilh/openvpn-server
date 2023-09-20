#!/bin/bash
#VERSION 0.2 by @d3vilh@github.com aka Mr. Philipp
# Exit immediately if a command exits with a non-zero status
set -e

# Set the path of the OpenVPN configuration file for the specified user
CERT_NAME=$1
CERT_IP=$2
CERT_PASS=$3
EASY_RSA=/usr/share/easy-rsa
OPENVPN_DIR=/etc/openvpn
OVPN_FILE_PATH="$OPENVPN_DIR/clients/$CERT_NAME.ovpn"

# Validate the specified username and check for duplicate files
if  [[ -z $CERT_NAME ]]; then
    echo 'Name cannot be empty.'
    exit 1
elif [[ -f $OVPN_FILE_PATH ]]; then
    echo "User with name $CERT_NAME already exists under openvpn/clients."
    exit 1
fi

# Set the EASYRSA_BATCH variable to enable non-interactive mode for easy-rsa
export EASYRSA_BATCH=1 # see https://superuser.com/questions/1331293/easy-rsa-v3-execute-build-ca-and-gen-req-silently

echo 'Patching easy-rsa.3.1.1 openssl-easyrsa.cnf...' 
sed -i '/serialNumber_default/d' $EASY_RSA/pki/openssl-easyrsa.cnf

echo 'Generating client certificate...'

# Change to the easy-rsa directory and copy the easy-rsa variables file
cd $EASY_RSA

# Check if a password was specified
if  [[ -z $CERT_PASS ]]; then
    echo 'Generating certificate without password...'
./easyrsa --batch --req-cn="$CERT_NAME" gen-req "$CERT_NAME" nopass 
else
    echo 'Generating certificate with password....'
    # See https://stackoverflow.com/questions/4294689/how-to-generate-an-openssl-key-using-a-passphrase-from-the-command-line
    # ... and https://stackoverflow.com/questions/22415601/using-easy-rsa-how-to-automate-client-server-creation-process
    # ... and https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Advanced.md
    # Use the specified password to generate the certificate
    (echo -e '\n') | ./easyrsa --batch --req-cn="$CERT_NAME" --passin=pass:${CERT_PASS} --passout=pass:${CERT_PASS} gen-req "$CERT_NAME"
fi

# Sign the certificate request
./easyrsa sign-req client "$CERT_NAME"

echo "Fixing Database..."
sed -i'.bak' "$ s/$/\/name=${CERT_NAME}\/LocalIP=${CERT_IP}/" $EASY_RSA/pki/index.txt

# Display the updated line in the index.txt file
echo "Database fixed:"
tail -1 $EASY_RSA/pki/index.txt

# Set variables for the CA certificate, client certificate, client key, and TLS authentication key
CA="$(cat ./pki/ca.crt )"
CERT="$(awk '/-----BEGIN CERTIFICATE-----/{flag=1;next}/-----END CERTIFICATE-----/{flag=0}flag' ./pki/issued/${CERT_NAME}.crt | tr -d '\0')"
KEY="$(cat ./pki/private/${CERT_NAME}.key)"
TLS_AUTH="$(cat ./pki/ta.key)"

echo 'Fixing permissions for pki/issued...'
chmod +r $EASY_RSA/pki/issued

# Create the .ovpn file for the specified user by combining the contents of the client.conf file with the CA certificate, client certificate, client key, and TLS authentication key
echo 'Generating .ovpn file...'
echo "$(cat $OPENVPN_DIR/config/client.conf)
<ca>
$CA
</ca>
<cert>
$CERT
</cert>
<key>
$KEY
</key>
<tls-auth>
$TLS_AUTH
</tls-auth>
" > "$OVPN_FILE_PATH"

echo "OpenVPN Client configuration successfully generated!\nCheckout openvpn-server/clients/$CERT_NAME.ovpn"