# CI-CD Server

## Installation
1. Si installation à partir d'un serveur vierge, suivre les étapes du [document `server-setup.md`](./server-setup.md) pour installer les pré-requis.
2. Ajouter la clé SSH publique du serveur dans le repo. Settings -> Deploy keys -> Add deploy key
    ```sh
    sudo cat /home/ci-cd/.ssh/id_ed25519.pub
    ```
3. Cloner le repo dans le répertoire de l'utilisateur sur le serveur
    ```sh
    cd ~ && git clone git@github.com:prox-i/ci-cd-server.git
    ```
4. Copier coller le fichier `template.env` et nommer la copie `.env`.
5. Mettre à jour la variable `DOMAIN_NAME` dans le `.env`.
6. Créer les réseaux internes Docker
    ```sh
    docker network create proxy && docker network create phpmyadmin
    ```
7. Démarrer le reverse-proxy
    ```sh
    docker compose -f ~/ci-cd-server/reverse-proxy/docker-compose.yml --env-file ~/ci-cd-server/.env up -d
    ```
8. Ajouter les scripts de backup à la crontab
    1. Créer et editer la crontab de l'utilisateur
        ```sh
        crontab -e
        ```
    2. Ajouter les lignes suivantes à la fin du fichier
        ```sh
        0 2 * * * TZ=Pacific/Tahiti /home/ci-cd/ci-cd-server/backups/cron_backup_all.sh.sh
        0 3 * * * TZ=Pacific/Tahiti /home/ci-cd/ci-cd-server/backups/cron_remove_old_backups.sh
        ```
9. Mettre en place la rotation des logs grâce à `logrotate`.
    1. Setup pour toutes les applications du dossier `~/applications`
        ```sh
        sudo sh -c 'echo   \
        "/home/ci-cd/applications/*/logs/*.log {
            weekly
            rotate 8
            copytruncate
            compress
            delaycompress
            notifempty
            missingok
            create 640 www-data adm
        }
        " > /etc/logrotate.d/docker-applications-proxi'
        ```
    2. Tester le bon fonctionnement
        ```sh
        sudo logrotate --debug /etc/logrotate.d/docker-applications-proxi
        ```
    3. Setup pour le reverse proxy `traefik`
        ```sh
        sudo sh -c 'echo   \
        "/home/ci-cd/ci-cd-server/reverse-proxy/logs/*.log {
            weekly
            rotate 8
            copytruncate
            compress
            delaycompress
            notifempty
            missingok
            create 640 www-data adm
        }
        " > /etc/logrotate.d/traefik'
        ```
    4. Rendre les logs de `traefik` éditables
        ```sh
        sudo chmod 700 /home/ci-cd/ci-cd-server/reverse-proxy/logs
        ```
    5. Tester le bon fonctionnement
        ```sh
        sudo logrotate --debug /etc/logrotate.d/traefik
        ```
