#!/bin/bash
# Enable unattended-upgrades for automatic security updates

apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

echo "Automatic security updates are enabled. Server will self-patch critical vulnerabilities."
