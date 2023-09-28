#!/bin/sh
# v.0.1 by @d3vilh@github.com aka Mr. Philipp
# d3vilh/openvpn-server drafted 2FA support
#
# MFA verification by OpenVPN server using oath-tool
echo "string oath.sh"
mkdir -p /etc/openvpn/log
# VARIABLES
PASSFILE=$1    # Password file passed by openvpn-server with "auth-user-pass-verify /opt/app/bin/oath.sh via-file" in server.conf
OPENVPN_DIR=/etc/openvpn
OATH_SECRETS=$OPENVPN_DIR/clients/oath.secrets
LOG_FILE=/var/log/openvpn/oath.log


echo "passfile: $PASSFILE"
echo "openvpn_dir: $OPENVPN_DIR"
echo "oath_secrets: $OATH_SECRETS"
echo "log_file: $LOG_FILE"

echo "$(date) - PASSFILE: $PASSFILE" | tee -a $LOG_FILE
cat $PASSFILE >> $LOG_FILE

# Geting user and password from passed by OpenVPN server tmp file
user=$(head -1 $PASSFILE)
pass=$(tail -1 $PASSFILE) 

echo "$(date) - Authentication attempt for user $user" | tee -a $LOG_FILE
echo "$(date) - Password: $pass" | tee -a $LOG_FILE


# Parsing oath.secrets to getting secret entry, ignore case
secret=$(grep -i -m 1 "$user:" $OATH_SECRETS | cut -d: -f2)

echo "$(date) - Secret: $secret" | tee -a $LOG_FILE

# Getting 2FA code with oathtool based on our secret, exiting with 0 if match:
code=$(oathtool --totp $secret)

echo "$(date) - Code: $code" | tee -a $LOG_FILE

if [ "$code" = "$pass" ];
then
    echo "OK"
   # echo "$(date) - Authentication succeeded for user $user" | tee -a $LOG_FILE
        exit 0
else 
echo "FAIL"
fi

# See if we have password and MFA, or just MFA

echo "$pass" | grep -q -i :

echo "$(date) - Password: $pass" | tee -a $LOG_FILE

if [ $? -eq 0 ];
then
        realpass=$(echo "$pass" | cut -d: -f1)
        mfatoken=$(echo "$pass" | cut -d: -f2)

        echo "$(date) - Real password: $realpass" | tee -a $LOG_FILE
        echo "$(date) - MFA token: $mfatoken" | tee -a $LOG_FILE

        # put code here to verify $realpass, the code below the if validates $mfatoken or $pass if false
        # exit 0 if the password is correct, the exit below will deny access otherwise
fi

# If we make it here, auth hasn't succeeded, don't grant access
echo "$(date) - Authentication failed for user $user" | tee -a $LOG_FILE
exit 1