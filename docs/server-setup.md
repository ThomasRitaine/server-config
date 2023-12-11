# Server Configuration

## Procedure: Setup from a Blank Server

### User Creation

1. Create the server management user.

   ```sh
   sudo useradd -s /bin/bash -m admin
   ```

2. Set a strong password for the user using a password generator. Store this password securely.

   ```sh
   sudo passwd admin
   ```

3. Generate an SSH key for the `admin` user, optionally restricting it to a specific IP address.

   1. Generate the key pair.
      ```sh
      sudo -u admin ssh-keygen -t ed25519 -a 200 -C "admin's SSH key on server"
      ```
   2. Add the public key to authorized keys with IP filtering (optional).
      ```sh
      sudo -u admin sh -c 'echo "from=\"YOUR_IP_ADDRESS\" " | cat - ~/.ssh/id_ed25519.pub > ~/.ssh/authorized_keys'
      ```
   3. Securely store the private key and remove it from the server.
      ```sh
      sudo -u admin sh -c 'cat ~/.ssh/id_ed25519 && rm ~/.ssh/id_ed25519\*'
      ```

4. Assign the default groups to the `admin` user.

   ```sh
   sudo usermod -aG $(id -Gn $USER | tr ' ' ',') admin
   ```

### SSH Key-Only Authentication

1. Ensure all SSH connections are key-based for security.

   1. Disable password authentication in `/etc/ssh/sshd_config`.

      - Set `PubkeyAuthentication yes`
      - Set `PasswordAuthentication no`
      - Add `AuthenticationMethods publickey`

   2. Restart the SSH services to apply changes.
      ```sh
      sudo systemctl restart sshd && sudo systemctl restart ssh
      ```

### Two-Factor Authentication Setup

1. Install the Google Authenticator PAM module.

   ```sh
   sudo apt install libpam-google-authenticator
   ```

2. Configure `sshd` for two-factor authentication.

   - Edit `/etc/pam.d/sshd` and `/etc/ssh/sshd_config` to enable challenge-response authentication.

3. Set up TOTP for the `admin` user.
   - Run `google-authenticator` as `admin` and follow the prompts.

### Server Renaming

1. Rename the server for easier identification.

   ```sh
   sudo vi /etc/hostname
   sudo vi /etc/hosts
   sudo reboot
   ```

### Dependency Installation

1. Update packages and install Docker.

2. Add the `admin` user to the Docker group.

   ```sh
   sudo usermod -aG docker admin
   ```

3. Install additional required dependencies.

   ```sh
   sudo apt-get install jq
   ```

### Setup Fail2Ban

1. **Install the Fail2Ban Package**:
   ```sh
   sudo apt install fail2ban
   ```
2. **Start the Fail2Ban Service**:
   ```sh
   sudo systemctl start fail2ban
   ```
3. **Enable Automatic Start of Fail2Ban**:
   ```sh
   sudo systemctl enable fail2ban
   ```
4. **Verify Fail2Ban Service Status**:
   ```sh
   sudo systemctl status fail2ban
   ```
5. **Create Custom Configuration File**:
   ```sh
   sudo vi /etc/fail2ban/jail.d/custom.conf
   ```
   Add the following content to customize settings:
   ```
   [DEFAULT]
   ignoreip = 167.114.36.33
   findtime = 10m
   bantime = 12h
   maxretry = 3
   ```
6. **Restart Fail2Ban Service**:
   ```sh
   sudo systemctl restart fail2ban
   ```

### Setup UFW Firewall

1. **Ensure Firewall is Disabled Initially**:
   ```sh
   sudo ufw disable
   ```
2. **Open Essential Ports (SSH, HTTP, HTTPS, Docker SFTP)**:
   ```sh
   sudo ufw allow ssh && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 2223/tcp
   ```
3. **Enable and Start UFW Firewall**:
   ```sh
   sudo ufw enable
   ```
4. **Check UFW Firewall Status**:
   ```sh
   sudo ufw status verbose
   ```

### Setup AWS CLI

The AWS CLI is required for uploading backups to S3-compatible storage (e.g., Wasabi).

1. **Download and Install AWS CLI**:
   ```sh
   sudo apt install unzip
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   rm awscliv2.zip
   ```
2. **Configure AWS CLI for `admin` User**:
   ```sh
   su admin
   aws configure
   ```
   Input only the `AWS Access Key ID` and `AWS Secret Access Key` when prompted; leave other fields blank.

This setup ensures the server has robust security measures, an effective firewall, and a reliable backup solution through AWS CLI.
