# d3vilh/openvpn-server
Fast Docker container with OpenVPN Server living inside.

[![latest version](https://img.shields.io/github/v/release/d3vilh/openvpn-server?color=%2344cc11&label=LATEST%20RELEASE&style=flat-square&logo=Github)](https://github.com/d3vilh/openvpn-server/releases/latest)  [![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/d3vilh/openvpn-server/latest?style=flat-square&logo=docker&logoColor=white&label=DOCKER%20IMAGE&color=2344cc11)](https://hub.docker.com/r/d3vilh/openvpn-server) ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/d3vilh/openvpn-server/latest?logo=Docker&color=2344cc11&label=IMAGE%20SIZE&style=flat-square&logoColor=white)

[![latest version](https://img.shields.io/github/v/release/d3vilh/openvpn-ui?color=%2344cc11&label=OpenVPN%20UI&style=flat-square&logo=Github)](https://github.com/d3vilh/openvpn-ui) [![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/d3vilh/openvpn-ui/latest?logo=docker&label=OpenVPN%20UI%20IMAGE&color=2344cc11&style=flat-square&logoColor=white)](https://hub.docker.com/r/d3vilh/openvpn-ui) 

## Important changes

### Release `v.0.5.1`
* Default OpenVPN Server configuration file has been moved from `/etc/openvpn/config` to `/etc/openvpn` directory.

### Release `v.0.4`
* Default Cipher for Server and Client configs is changed to `AES-256-GCM`
* **`ncp-ciphers`** option has been depricated and replaced with **`data-ciphers`**
* 2FA support has been added

## Automated installation
Consider to use [openvpn-aws](https://github.com/d3vilh/openvpn-aws) as automated installation solution. It will deploy OpenVPN Server on any x86 server or Cloud instance with all the required configuration and OpenVPN UI for easy management.

## Run this image

### Run image using a `docker-compose.yml` file

1. Clone the repo:
```shell
git clone https://github.com/d3vilh/openvpn-server
```
> **Note**: Before deploying container check [Deployment Details](https://github.com/d3vilh/openvpn-server#container-deployment-details) section for setting all the required variables up.
2. Build the image:
```shell
cd openvpn-server
docker compose up -d
```
3. That's it. It seems you have your own openvpn-server running on your machine.

For easy **OpenVPN Server** management install [**OpenVPN-UI**](https://github.com/d3vilh/openvpn-ui).

## Container deployment details

### Docker-compose.yml:
```yaml
---
version: "3.5"

services:
    openvpn:
       container_name: openvpn
       # If you want to build your own image with docker-compose, uncomment the next line, comment the "image:" line and run "docker-compose build" following by "docker-compose up -d"
       # build: .
       image: d3vilh/openvpn-server:latest
       privileged: true
       ports: 
          - "1194:1194/udp"   # openvpn UDP port
         # - "1194:1194/tcp"   # openvpn TCP port
         # - "2080:2080/tcp"  # management port. uncomment if you would like to share it with the host
       environment:
           TRUST_SUB: "10.0.70.0/24"
           GUEST_SUB: "10.0.71.0/24"  
           HOME_SUB: "192.168.88.0/24"
       volumes:
           - ./pki:/etc/openvpn/pki
           - ./clients:/etc/openvpn/clients
           - ./config:/etc/openvpn/config
           - ./staticclients:/etc/openvpn/staticclients
           - ./log:/var/log/openvpn
           - ./fw-rules.sh:/opt/app/fw-rules.sh
           - ./checkpsw.sh:/opt/app/checkpsw.sh
           - ./server.conf:/etc/openvpn/server.conf
       cap_add:
           - NET_ADMIN
       restart: always
       depends_on:
           - "openvpn-ui"

    openvpn-ui:
       container_name: openvpn-ui
       image: d3vilh/openvpn-ui:latest
       environment:
           - OPENVPN_ADMIN_USERNAME=admin
           - OPENVPN_ADMIN_PASSWORD=gagaZush
       privileged: true
       ports:
           - "8080:8080/tcp"
       volumes:
           - ./:/etc/openvpn
           - ./db:/opt/openvpn-ui/db
           - ./pki:/usr/share/easy-rsa/pki
           - /var/run/docker.sock:/var/run/docker.sock:ro
       restart: always

``` 

**Where:** 
* `TRUST_SUB` is Trusted subnet, from which OpenVPN server will assign IPs to trusted clients (default subnet for all clients)
* `GUEST_SUB` is Gusets subnet for clients with internet access only
* `HOME_SUB` is subnet where the VPN server is located, thru which you get internet access to the clients with MASQUERADE
* `fw-rules.sh` is bash file with additional firewall rules you would like to apply during container start
* `checkpsw.sh` is a dummy bash script to use with `auth-user-pass-verify` option in `server.conf` file. It is used to check user credentials against some external passwords DB, like LDAP or oath, or MySQL. If you don't need this option, just leave it as is.

`docker_entrypoint.sh` will apply following Firewall rules:
```shell
IPT MASQ Chains:
MASQUERADE  all  --  ip-10-0-70-0.ec2.internal/24  anywhere
MASQUERADE  all  --  ip-10-0-71-0.ec2.internal/24  anywhere
IPT FWD Chains:
       0        0 DROP       1    --  *      *       10.0.71.0/24         0.0.0.0/0            icmptype 8
       0        0 DROP       1    --  *      *       10.0.71.0/24         0.0.0.0/0            icmptype 0
       0        0 DROP       0    --  *      *       10.0.71.0/24         192.168.88.0/24
``` 
Here is possible content of `fw-rules.sh` file to apply additional rules:
```shell
~/openvpn-server $ cat fw-rules.sh
iptables -A FORWARD -s 10.0.70.88 -d 10.0.70.77 -j DROP
iptables -A FORWARD -d 10.0.70.77 -s 10.0.70.88 -j DROP
```

<img src="https://github.com/d3vilh/raspberry-gateway/raw/master/images/OVPN_VLANs.png" alt="OpenVPN Subnets" width="700" border="1" />

Check attached `docker-compose-no-ui.yml` file to run openvpn-server withput [OpenVPN UI](https://github.com/d3vilh/openvpn-ui) container.

**Default EasyRSA** configuration can be changed in `~/openvpn-server/config/easy-rsa.vars` file:

```shell
set_var EASYRSA_DN           "org"
set_var EASYRSA_REQ_COUNTRY  "UA"
set_var EASYRSA_REQ_PROVINCE "KY"
set_var EASYRSA_REQ_CITY     "Kyiv"
set_var EASYRSA_REQ_ORG      "SweetHome"
set_var EASYRSA_REQ_EMAIL    "sweet@home.net"
set_var EASYRSA_REQ_OU       "MyOrganizationalUnit"
set_var EASYRSA_REQ_CN       "server"
set_var EASYRSA_KEY_SIZE     2048
set_var EASYRSA_CA_EXPIRE    3650
set_var EASYRSA_CERT_EXPIRE  825
set_var EASYRSA_CERT_RENEW   30
set_var EASYRSA_CRL_DAYS     180
```

In the process of installation these vars will be copied to container volume `/etc/openvpn/pki/vars` and used during all EasyRSA operations.
You can update all these parameters later with OpenVPN UI on `Configuration > EasyRSA vars` page.


### Run with Docker:
```shell
docker run  --interactive --tty --rm \
  --name=openvpn \
  --cap-add=NET_ADMIN \
  -p 1194:1194/udp \
  -e TRUST_SUB=10.0.70.0/24 \
  -e GUEST_SUB=10.0.71.0/24 \
  -e HOME_SUB=192.168.88.0/24 \
  -v ./pki:/etc/openvpn/pki \
  -v ./clients:/etc/openvpn/clients \
  -v ./config:/etc/openvpn/config \
  -v ./staticclients:/etc/openvpn/staticclients \
  -v ./log:/var/log/openvpn \
  -v ./fw-rules.sh:/opt/app/fw-rules.sh \
  -v ./server.conf:/etc/openvpn/server.conf \
  --privileged d3vilh/openvpn-server:latest
```

### Run the OpenVPN-UI image
```
docker run \
-v /home/pi/openvpn-server:/etc/openvpn \
-v /home/pi/openvpn-server/db:/opt/openvpn-ui/db \
-v /home/pi/openvpn-server/pki:/usr/share/easy-rsa/pki \
-e OPENVPN_ADMIN_USERNAME='admin' \
-e OPENVPN_ADMIN_PASSWORD='gagaZush' \
-p 8080:8080/tcp \
--privileged d3vilh/openvpn-ui:latest
```

### Build image form scratch:
1. Clone the repo:
```shell
git clone https://github.com/d3vilh/openvpn-server
```
2. Build the image:
```shell
cd openvpn-server
docker build --force-rm=true -t d3vilh/openvpn-server .
```

## Configuration

The volume container will be initialised  with included scripts to automatically generate everything you need on the first run:
 - Diffie-Hellman parameters
 - an EasyRSA CA key and certificate
 - a new private key
 - a self-certificate matching the private key for the OpenVPN server
 - a TLS auth key from HMAC security

This setup use `tun` mode, as the most compatible with wide range of devices, for instance, does not work on MacOS(without special workarounds) and on Android (unless it is rooted).

The topology used is `subnet`, for the same reasons. `p2p`, for instance, does not work on Windows.

The server config [specifies](https://github.com/d3vilh/openvpn-aws/blob/master/openvpn/server.conf#L34) `push redirect-gateway def1 bypass-dhcp`, meaning that after establishing the VPN connection, all traffic will go through the VPN. This might cause problems if you use local DNS recursors which are not directly reachable, since you will try to reach them through the VPN and they might not answer to you. If that happens, use public DNS resolvers like those of OpenDNS (`208.67.222.222` and `208.67.220.220`) or Google (`8.8.4.4` and `8.8.8.8`).

### OpenVPN Server Pstree structure

All the Server and Client configuration located in mounted Docker volume and can be easely tuned. Here is the tree structure:

```shell
|-- server.conf  // OpenVPN Server configuration file
|-- clients
|   |-- your_client1.ovpn
|-- config
|   |-- client.conf
|   |-- easy-rsa.vars
|-- db
|   |-- data.db //Optional OpenVPN UI DB
|-- log
|   |-- openvpn.log
|-- pki
|   |-- ca.crt
|   |-- certs_by_serial
|   |   |-- your_client1_serial.pem
|   |-- crl.pem
|   |-- dh.pem
|   |-- index.txt
|   |-- ipp.txt
|   |-- issued
|   |   |-- server.crt
|   |   |-- your_client1.crt
|   |-- openssl-easyrsa.cnf
|   |-- private
|   |   |-- ca.key
|   |   |-- your_client1.key
|   |   |-- server.key
|   |-- renewed
|   |   |-- certs_by_serial
|   |   |-- private_by_serial
|   |   |-- reqs_by_serial
|   |-- reqs
|   |   |-- server.req
|   |   |-- your_client1.req
|   |-- revoked
|   |   |-- certs_by_serial
|   |   |-- private_by_serial
|   |   |-- reqs_by_serial
|   |-- safessl-easyrsa.cnf
|   |-- serial
|   |-- ta.key
|-- staticclients //Directory where stored all the satic clients configuration
```

### Generating .OVPN client profiles with [OpenVPN UI](https://github.com/d3vilh/openvpn-ui)

You can access **OpenVPN UI** on it's own port (*e.g. `http://localhost:8080`, change `localhost` to your Public or Private IPv4 address*), the default user and password is `admin/gagaZush` which can be changed via Docker enviroment.

You can update external client IP and port address anytime under `"Configuration > OpenVPN Client"` menu. 

For this go to `"Configuration > OpenVPN Client"`:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-ext_serv_ip1.png" alt="Configuration > Settings" width="350" border="1" />

And then update `"Connection Address"` and `"Connection Port"` fields with your external Internet IP and Port. 

To generate new Client Certificate go to `"Certificates"`, then press `"Create Certificate"` button, enter new VPN client name, complete all the rest fields and press `"Create"` to generate new Client certificate:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-ext_serv_ip2.png" alt="Server Address" width="350" border="1" />  <img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-New_Client.png" alt="Create Certificate" width="350" border="1" />

To download .OVPN client configuration file, press on the `Client Name` you just created:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-New_Client_download.png" alt="download OVPN" width="350" border="1" />

Install [Official OpenVPN client](https://openvpn.net/vpn-client/) to your client device.

Deliver .OVPN profile to the client device and import it as a FILE, then connect with new profile to enjoy your free VPN:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Palm_import.png" alt="PalmTX Import" width="350" border="1" /> <img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Palm_connected.png" alt="PalmTX Connected" width="350" border="1" />

### Renew Certificates for client profiles

To renew certificate, go to `"Certificates"` and press `"Renew"` button for the client you would like to renew certificate for:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Cert-Renew.01.png" alt="Renew OpenVPN Certificate" width="600" border="1" />

Right after this step new Certificate will be genrated and it will appear as new client profile with the same Client name. At this point both client profiles will have updated Certificate when you try to download it.

Once you will deliver new client profile with renewed Certificate to you client, press `"Revoke"` button for old profile to revoke old Certificate, old client profile will be deleted from the list.

If, for some reason you still would like to keep old certificate you have to `"Revoke"` new profile, old certificate will be rolled back and new profile will be deleted from the list.

Renewal process will not affect active VPN connections, old client will be disconnected only after you revoke old certificate or certificate term of use will expire.

### Revoking .OVPN profiles

If you would like to prevent client to use yor VPN connection, you have to revoke client certificate and restart the OpenVPN daemon.
You can do it via OpenVPN UI `"Certificates"` menue, by pressing `"Revoke"`` amber button:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Revoke.png" alt="Revoke Certificate" width="600" border="1" />

Certificate revoke won't kill active VPN connections, you'll have to restart the service if you want the user to immediately disconnect. It can be done from the same `"Certificates"` page, by pressing Restart red button:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Restart.png" alt="OpenVPN Restart" width="600" border="1" />

You can do the same from the `"Maintenance"` page.

After Revoking and Restarting the service, the client will be disconnected and will not be able to connect again with the same certificate. To delete the certificate from the server, you have to press `"Remove"` button.

### OpenVPN client subnets. Guest and Home users

By default this [Openvpn-Server](https://github.com/d3vilh/openvpn-server) OpenVPN server uses option `server 10.0.70.0/24` as **"Trusted"** subnet to grab dynamic IPs for all your Clients which, by default will have full access to your **"Private/Home"** subnet, as well as Internet over VPN.
However you can be desired to share internet over VPN with specific, Guest Clients and restrict access to your **"Private/Home"** subnet. For this scenario [Openvpn-Server's](https://github.com/d3vilh/openvpn-server) `server.conf` configuration file has special `route 10.0.71.0/24` option, aka **"Guest users"** subnet.

<p align="center">
<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OVPN_VLANs.png" alt="OpenVPN Subnets" width="700" border="1" />
</p>

To assign desired subnet policy to the specific client, you have to define static IP address for the client during its profile/Certificate creation.
To do that, just enter `"Static IP (optional)"` field in `"Certificates"` page and press `"Create"` button.

> Keep in mind, by default, all the clients have full access, so you don't need to specifically configure static IP for your own devices, your home devices always will land to **"Trusted"** subnet by default. 

### CLI ways to deal with OpenVPN Server configuration

To **generate** new .OVPN profile execute following command. Password as second argument is optional:
```shell
sudo docker exec openvpn bash /opt/app/bin/genclient.sh <name> <IP> <?password?>
```

You can find you .ovpn file under `/openvpn/clients/<name>.ovpn`, make sure to check and modify the `remote ip-address`, `port` and `protocol`. It also will appear in `"Certificates"` menue of OpenVPN UI.

**Revoking** of old .OVPN files can be done via CLI by running following:

```shell
sudo docker exec openvpn bash /opt/app/bin/revoke.sh <clientname>
```

**Removing** of old .OVPN files can be done via CLI by running following:

```shell
sudo docker exec openvpn bash /opt/app/bin/rmcert.sh <clientname>
```

Restart of OpenVPN container can be done via the CLI by running following:
```shell
sudo docker restart openvpn
```

To define static IP, go to `~/openvpn/staticclients` directory and create text file with the name of your client and insert into this file ifrconfig-push option with the desired static IP and mask: `ifconfig-push 10.0.71.2 255.255.255.0`.

For example, if you would like to restrict Home subnet access to your best friend Slava, you should do this:

```shell
slava@Ukraini:~/openvpn/staticclients $ pwd
/home/slava/openvpn/staticclients
slava@Ukraini:~/openvpn/staticclients $ ls -lrt | grep Slava
-rw-r--r-- 1 slava heroi 38 Nov  9 20:53 Slava
slava@Ukraini:~/openvpn/staticclients $ cat Slava
ifconfig-push 10.0.71.2 255.255.255.0
```

> Keep in mind, by default, all the clients have full access, so you don't need to specifically configure static IP for your own devices, your home devices always will land to **"Trusted"** subnet by default. 


### Screenshots of managing OpenVPN Server with OpenVPN UI:

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Login.png" alt="OpenVPN-UI Login screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Home.png" alt="OpenVPN-UI Home screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Certs.png" alt="OpenVPN-UI Certificates screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Create-Cert.png" alt="OpenVPN-UI Create Certificate screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Certs-Details-Expire.png" alt="OpenVPN-UI Expire Certificate details" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Certs-Details_OK.png" alt="OpenVPN-UI OK Certificate details" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-EasyRsaVars.png" alt="OpenVPN-UI EasyRSA vars screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-EasyRsaVars-View.png" alt="OpenVPN-UI EasyRSA vars config view screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Maintenance.png" alt="OpenVPN-UI Maintenance screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Server-config.png" alt="OpenVPN-UI Server Configuration screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Server-config-edit.png" alt="OpenVPN-UI Server Configuration edit screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-ClientConf.png" alt="OpenVPN-UI Client Configuration screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Config.png" alt="OpenVPN-UI Configuration screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Profile.png" alt="OpenVPN-UI User Profile" width="1000" border="1" />

<img src="https://github.com/d3vilh/openvpn-ui/blob/main/docs/images/OpenVPN-UI-Logs.png" alt="OpenVPN-UI Logs screen" width="1000" border="1" />

<a href="https://www.buymeacoffee.com/d3vilh" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="51" width="217"></a>
