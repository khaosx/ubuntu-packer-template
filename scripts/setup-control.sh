#!/bin/bash -eux

# Create .ssh directory for jarvis
mkdir -p /home/jarvis/.ssh
touch /home/jarvis/.ssh/authorized_keys
touch /home/jarvis/.ssh/known_hosts

# Add ssh keys for jarvis
cat /tmp/jarvis_rsa.pub > /home/jarvis/.ssh/authorized_keys
mv /tmp/jarvis_rsa /home/jarvis/.ssh/id_rsa
mv /tmp/jarvis_rsa.pub /home/jarvis/.ssh/id_rsa.pub

# Change permissions for jarvis SSH keys
chown -R jarvis:jarvis /home/jarvis/.ssh
chmod 700 /home/jarvis/.ssh
chmod 600 /home/jarvis/.ssh/id_rsa
chmod 644 /home/jarvis/.ssh/id_rsa.pub
chmod 644 /home/jarvis/.ssh/authorized_keys
chmod 644 /home/jarvis/.ssh/known_hosts

# Install Ansible repository.
apt-get -y update && apt-get -y upgrade
apt-add-repository ppa:ansible/ansible

# Install Ansible.
apt-get -y update
apt-get -y install ansible