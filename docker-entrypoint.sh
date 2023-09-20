#!/bin/bash
#VERSION 0.2 by @d3vilh@github.com aka Mr. Philipp
set -e

#Variables
EASY_RSA=/usr/share/easy-rsa
OPENVPN_DIR=/etc/openvpn
echo "EasyRSA path: $EASY_RSA OVPN path: $OPENVPN_DIR"

if [[ ! -f $OPENVPN_DIR/pki/ca.crt ]]; then
    export EASYRSA_BATCH=1 # see https://superuser.com/questions/1331293/easy-rsa-v3-execute-build-ca-and-gen-req-silently
    cd $EASY_RSA

    # Building the CA
    echo 'Setting up public key infrastructure...'
    $EASY_RSA/easyrsa init-pki

    # Copy easy-rsa variables
    cp $OPENVPN_DIR/config/easy-rsa.vars $EASY_RSA/pki/vars

    # Listing env parameters:
    echo "Following EASYRSA variables will be used:"
    cat $EASY_RSA/pki/vars | awk '{$1=""; print $0}';

    echo 'Generating ertificate authority...'
    $EASY_RSA/easyrsa build-ca nopass

    # Creating the Server Certificate, Key, and Encryption Files
    echo 'Creating the Server Certificate...'
    $EASY_RSA/easyrsa gen-req server nopass

    echo 'Sign request...'
    $EASY_RSA/easyrsa sign-req server server

    echo 'Generate Diffie-Hellman key...'
    $EASY_RSA/easyrsa gen-dh

    echo 'Generate HMAC signature...'
    openvpn --genkey --secret $EASY_RSA/pki/ta.key

    echo 'Create certificate revocation list (CRL)...'
    $EASY_RSA/easyrsa gen-crl
    chmod +r $EASY_RSA/pki/crl.pem

    # Copy to mounted volume
    cp -r $EASY_RSA/pki/. $OPENVPN_DIR/pki
else

    echo 'PKI already set up.'
fi

# Listing env parameters:
echo "Following EASYRSA variables were set during CA init:"
cat $EASY_RSA/pki/vars | awk '{$1=""; print $0}';

# Configure network
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

echo 'Configuring networking rules...'
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

echo 'Configuring iptables...'
echo 'NAT for OpenVPN clients'
iptables -t nat -A POSTROUTING -s $TRUST_SUB -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s $GUEST_SUB -o eth0 -j MASQUERADE

echo 'Blocking ICMP for external clients'
iptables -A FORWARD -p icmp -j DROP --icmp-type echo-request -s $GUEST_SUB 
iptables -A FORWARD -p icmp -j DROP --icmp-type echo-reply -s $GUEST_SUB 

echo 'Blocking internal home subnet to access from external openvpn clients (Internet still available)'
iptables -A FORWARD -s $GUEST_SUB -d $HOME_SUB -j DROP

if [[ ! -s fw-rules.sh ]]; then
    echo "No additional firewall rules to apply."
else
    echo "Applying firewall rules"
    ./fw-rules.sh
    echo 'Additional firewall rules applied.'
fi

echo 'IPT MASQ Chains:'
iptables -t nat -L | grep MASQ
echo 'IPT FWD Chains:'
iptables -v -x -n -L | grep DROP 

echo 'Start openvpn process...'
/usr/sbin/openvpn --cd $OPENVPN_DIR --script-security 2 --config $OPENVPN_DIR/config/server.conf