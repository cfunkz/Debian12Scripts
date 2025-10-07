#!/bin/bash
# Install two key scanners for rootkit & malware

apt update
apt install -y chkrootkit rkhunter

chkrootkit
rkhunter --update
rkhunter --check --skip-keypress

echo "Rootkit and malware scanning tools installed and run."
