# Installation Guide

## Overview

This guide will walk you through setting up a NixOS VPS with the server configuration provided in this repository. You'll set up the server, configure NixOS, and deploy the services using Docker.

## Prerequisites

- A VPS capable of running NixOS or a VPS hosting provider that allows you to upload your own ISO image. (Personally, I use a Netcup VPS.)
- Basic knowledge of Linux command-line operations.
- SSH access to your VPS.

## Step 1: Install NixOS on Your VPS

Follow these steps to install NixOS on your VPS.

### 1.1 Partitioning the Disk

Log into your VPS console and partition the disk:

```sh
parted /dev/vda

# In the parted console:
mklabel gpt
mkpart ESP fat32 1MiB 513MiB
set 1 boot on
mkpart primary ext4 513MiB -8GiB
mkpart primary linux-swap -8GiB 100%
quit
```

Verify the partitions:

```sh
lsblk /dev/vda
```

### 1.2 Formatting the Partitions

Format the partitions:

```sh
mkfs.vfat -n EFI /dev/vda1
mkfs.ext4 -L nixos /dev/vda2
mkswap /dev/vda3
```

### 1.3 Mounting the Filesystem

Mount the filesystem:

```sh
mount /dev/vda2 /mnt
mkdir -p /mnt/boot
mount /dev/vda1 /mnt/boot
swapon /dev/vda3
```

### 1.4 Generate NixOS Configuration

Generate the NixOS configuration files:

```sh
nixos-generate-config --root /mnt
```

### 1.5 Set Passwords

Create a directory for hashed passwords:

```sh
mkdir -p /mnt/etc/nixos/secrets
```

Generate hashed passwords for users:

```sh
mkpasswd > /mnt/etc/nixos/secrets/root-password
mkpasswd > /mnt/etc/nixos/secrets/thomas-password
mkpasswd > /mnt/etc/nixos/secrets/app-manager-password
```

Set permissions:

```sh
chown -R root:root /mnt/etc/nixos/secrets
chmod 700 /mnt/etc/nixos/secrets
chmod 600 /mnt/etc/nixos/secrets/*
```

### 1.6 Edit NixOS Configuration

Edit the NixOS configuration files:

```sh
vi /mnt/etc/nixos/configuration.nix
vi /mnt/etc/nixos/zsh.nix
```

Ensure that you include the necessary configurations for your users, SSH keys, Docker installation, and other services as per your requirements.

### 1.7 Install Home Manager

Install Home Manager:

```sh
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
sudo nix-channel --update
```

### 1.8 Install NixOS

Install NixOS:

```sh
nixos-install
```

Reboot the system:

```sh
reboot
```

## Step 2: Initial Server Setup

### 2.1 Clone the Server Configuration Repository

Log in as the `app-manager` user and clone the repository:

```sh
git clone https://github.com/ThomasRitaine/server-config.git
```

### 2.2 Clone Additional Repositories

If needed, clone additional repositories:

```sh
su root
git clone https://github.com/ThomasRitaine/terminal.git /opt/
```

### 2.3 Set Up Environment Variables

Copy the `.env.example` file to `.env` and edit it with your environment variables:

```sh
cd ~/server-config
cp .env.example .env
vi .env
```

Set the `DOMAIN_NAME`, `S3_BUCKET_NAME`, `S3_ENDPOINT`, and any other required variables.

### 2.4 Configure AWS CLI

Configure AWS CLI to enable backups to S3-compatible storage:

```sh
aws configure
```

Provide your `AWS Access Key ID`, `AWS Secret Access Key`, and the default region. You can leave the default output format blank.

### 2.5 Start Docker Services

Start Traefik:

```sh
docker compose -f ~/server-config/traefik/docker-compose.yml --env-file ~/server-config/.env up -d
```

Start Authentik:

```sh
docker compose -f ~/server-config/authentik/docker-compose.yml --env-file ~/server-config/.env up -d
```

Start DBeaver:

```sh
docker compose -f ~/server-config/dbeaver/docker-compose.yml --env-file ~/server-config/.env up -d
```

### 2.6 Create Docker Networks

Create the necessary Docker networks:

```sh
docker network create traefik
docker network create dbeaver
```

## Step 3: Configure Backup System

### 3.1 Configure Backup Scripts

Ensure that the backup scripts are executable:

```sh
chmod +x ~/server-config/backup/cron_backup.sh
chmod +x ~/server-config/backup/restore_backup.sh
```

### 3.2 Configure Applications for Backup

For each application in `/home/app-manager/applications`:

- Ensure the application directory is included in the backup.
- To backup Docker volumes, create a `.backup` file in the application's directory.
- In the `.backup` file, list the names of the Docker volumes to backup, one per line.
- Alternatively, use an asterisk `*` to backup all Docker volumes for that application.

## Step 4: Deploy Your Applications

Now you can deploy your own applications by placing them in the `/home/app-manager/applications` directory, configuring their `docker-compose.yml` files, and starting them.

Ensure that:

- Your applications are connected to the `traefik` network.
- You have appropriate Traefik labels set up for routing.
- You configure Authentik middleware if needed.

## Additional Notes

- **SSH Key-Based Authentication**: Ensure that SSH access is configured with key-based authentication for security.
- **Fail2Ban and UFW**: Configure Fail2Ban and UFW firewall to protect your server from unauthorized access.
- **Authentik Configuration**: Set up Authentik according to your requirements for user authentication and SSO.

---

This installation guide integrates the NixOS installation steps and removes TOTP authentication as per the updated configuration. It provides a comprehensive walkthrough from setting up NixOS to deploying Docker services and configuring backups.

Please refer to the [README.md](README.md) for more details about the project and its features.
