# Server Config

## Installation

1. **Initial Server Preparation**: Begin by setting up your server based on the [`server-setup.md`](./server-setup.md) guide. This ensures that the server has all the necessary security configurations and user setup.

2. **Repository Cloning**: Clone the repository into the server's user directory. This will be your working directory for server configuration.

   ```sh
   cd ~ && git clone https://github.com/ThomasRitaine/server-config
   ```

3. **Environment Configuration**: Duplicate the `.env.example` file, rename it to `.env`, and fill in the necessary environment variables.

   ```sh
   cp .env.example .env
   ```

4. **Docker Network Creation**: Set up Docker networks for your applications and the Traefik proxy.

   ```sh
   docker network create traefik && docker network create dbeaver
   ```

5. **Reverse Proxy Startup**: Deploy Traefik using its Docker Compose file to handle incoming requests and route them to the correct containers.

   ```sh
   docker compose -f ~/server-config/traefik/docker-compose.yml --env-file ~/server-config/.env up -d
   ```

6. **Backup Scripts Configuration**: Add backup scripts to the user's crontab for automated backup execution.

   ```sh
   crontab -e
   ```

   Add the following lines to automate backups:

   ```vim
   0 2 * * * /home/app-manager/server-config/backup/cron_backup.sh >> /home/app-manager/server-config/backup/logs/cron_run.log 2>&1
   ```

7. **Log Rotation with Logrotate**: Set up `logrotate` to manage log file rotation and archiving. This prevents log files from consuming too much disk space.
   1. Configure `logrotate` for application logs.
      ```sh
      sudo sh -c 'echo "/home/app-manager/applications/_/logs/_.log {...}" > /etc/logrotate.d/docker-applications'
      sudo logrotate --debug /etc/logrotate.d/docker-applications
      ```
   2. Set up `logrotate` for Traefik logs.
      ```sh
      sudo sh -c 'echo "/home/app-manager/server-config/traefik/logs/\*.log {...}" > /etc/logrotate.d/traefik'
      sudo chmod 700 /home/app-manager/server-config/traefik/logs
      sudo logrotate --debug /etc/logrotate.d/traefik
      ```
