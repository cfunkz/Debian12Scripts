#!/bin/bash
# Secure SSH Setup & Optional Password for User

# Variables
USERNAME="newuser"
PUB_KEY="SSH PUB"
SSH_PORT=22
VOLUME_HOME="/home/$USERNAME"

# Optional: set password via environment variable
# PASSWD="mypassword"  # Uncomment to set password non-interactively

# 1️⃣ Create user and add to sudo
if ! id -u $USERNAME >/dev/null 2>&1; then
    # Create user with disabled password
    adduser --disabled-password --gecos "" $USERNAME
    usermod -aG sudo $USERNAME
    echo "User $USERNAME created and added to sudo group."
else
    echo "User $USERNAME already exists."
fi

# 2️⃣ Set password for the user
if [ -z "$PASSWD" ]; then
    echo "Please enter password for $USERNAME:"
    passwd $USERNAME
else
    echo "$USERNAME:$PASSWD" | chpasswd
    echo "Password set for $USERNAME from PASSWD variable."
fi

# 3️⃣ Install sudo if not present and update packages
apt update && apt upgrade -y
apt install -y sudo

# 4️⃣ Setup SSH folder & authorized_keys
mkdir -p $VOLUME_HOME/.ssh
chmod 700 $VOLUME_HOME/.ssh
echo "$PUB_KEY" > $VOLUME_HOME/.ssh/authorized_keys
chmod 600 $VOLUME_HOME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME $VOLUME_HOME/.ssh
echo "SSH authorized_keys set for $USERNAME."

# 5️⃣ Backup existing sshd_config
SSHD_CONF="/etc/ssh/sshd_config"
cp $SSHD_CONF "${SSHD_CONF}.bak.$(date +%F-%T)"
echo "Backed up $SSHD_CONF to ${SSHD_CONF}.bak.$(date +%F-%T)"

# 6️⃣ Harden SSH config
cat > $SSHD_CONF <<EOF
# Basic settings
Port $SSH_PORT
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# Disable root login
PermitRootLogin no

# Key-based authentication only
PubkeyAuthentication yes
AuthorizedKeysFile     .ssh/authorized_keys

# Disable all password authentication
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM no
PermitEmptyPasswords no

# Security & usability
PermitTunnel no
AllowAgentForwarding yes
AllowTcpForwarding yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
ClientAliveInterval 120
ClientAliveCountMax 3

# SFTP subsystem
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF

echo "sshd_config updated."

# 7️⃣ Restart SSH service
if systemctl status ssh >/dev/null 2>&1; then
    systemctl restart ssh
    echo "SSH service restarted."
else
    service ssh restart
    echo "SSH service restarted using service command."
fi

echo "Setup complete! You can now login as $USERNAME using your SSH key only."
