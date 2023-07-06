# CI-CD Server

## Procédure : Setup à partir d'un serveur vierge

### Créer les utilisateurs

1. Créer les 2 utilisateurs de gestion du serveur.
    ```sh
    sudo useradd -s /bin/bash -m it-sense && sudo useradd -s /bin/bash -m prox-i
    ```

2. Setup les mots de passe de ces deux utilisateurs en utilisant le [générateur de mot de passe LastPass](https://www.lastpass.com/fr/features/password-generator) avec une longueur de 24 charactères, majuscules, minuscules, chiffres et symboles. Ajouter ces mots de passe à la note LastPass du serveur.
    ```sh
    sudo passwd it-sense
    ```
    ```sh
    sudo passwd prox-i
    ```

3. Créer une clé SSH pour les deux utilisateurs `it-sense` et `prox-i`. (les étapes suivantes sont faites pour `prox-i`, adapter pour `it-sense`)
    1. Créer un couple de clé. Appuyer sur entrer pour accepter la configuration par défaut
        ```sh
        sudo -u prox-i ssh-keygen -t ed25519 -a 200 -C "Clé SSH de l'utilisateur prox-i sur le serveur de pré-prod de #Prox-i"
        ```
    2. Mettre la clé publique dans les clés autorisées. Adapter avec le filtrage IP souhaité car ici, `167.114.36.33` est l'IP du VPS de #Prox-i qui host le VPN WireGuard. Pour `it-sense`, mettre l'adresse IP de leur VPN. (bien vérifier que toutes les info du `authorized_keys` sont sur la même ligne)
        ```sh
        sudo -u prox-i sh -c 'echo "from=\"167.114.36.33\" " | cat - ~/.ssh/id_ed25519.pub > ~/.ssh/authorized_keys'
        ```
    3. Noter la clé privée dans LastPass puis supprimer les clés du serveur.
        ```sh
        sudo -u prox-i sh -c 'cat ~/.ssh/id_ed25519 && rm ~/.ssh/id_ed25519*'
        ```

4. Donner les groupes par défaut aux utilisateurs `prox-i` et `it-sense`
    ```sh
    sudo usermod -aG $(id -Gn $USER | tr ' ' ',') it-sense && sudo usermod -aG $(id -Gn $USER | tr ' ' ',') prox-i
    ```

5. Se déconnecter du serveur
    ```sh
    exit
    ```

6. Se connecter au VPN de #Prox-i, puis se reconnecter en tant que `prox-i` sur le serveur (remplacer `<ip_server>` par l'IP du serveur)
    1. Sur la machine locale, créer un fichier vide pour stocker la clé privée de l'utilisateur `prox-i` sur le serveur. La clé crée s'appelle `pre-prod-prox-i-key`, adapter si setup du serveur de prod, adapter le nom de l'utilisateur si besoin.
        ```sh
        mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/pre-prod-prox-i-key && chmod 600 ~/.ssh/pre-prod-prox-i-key
        ```
    2. Copier le contenu de la clé dans le fichier créé. (`Ctrl + V` puis `:wq`)
        ```sh
        vi ~/.ssh/pre-prod-prox-i-key
        ```
    3. Se connecter au serveur avec la clé via le VPN.
        ```sh
        ssh -i ~/.ssh/pre-prod-prox-i-key prox-i@<ip_server>
        ```

7. Renommer l'utilisateur `ubuntu` en `ci-cd` (adapter le nom d'utilisateur par défaut, ce ne sera pas forcément `ubuntu`)
    ```sh
    sudo usermod -l ci-cd ubuntu && sudo usermod -d /home/ci-cd -m ci-cd
    ```

8. Réduire les permissions acoordées à `ci-cd`
    ```sh
    sudo groupadd ci-cd && sudo usermod -G ci-cd ci-cd
    ```

9. Ajouter `prox-i` et `it-sense` au groupe `ci-cd`
    ```sh
    sudo usermod -aG ci-cd it-sense && sudo usermod -aG ci-cd prox-i
    ```

10. Si besoin, ajouter les permissions de lecture et d'exécution sur les dossiers et fichiers le demandant.
    ```sh
    sudo chmod g+rx ~/.docker
    ```

### Autoriser des connexions SSH uniquement avec des clés publiques/privées

1. Regarder la liste des fichiers dans `/etc/ssh/sshd_config.d`
    ```sh
    ls /etc/ssh/sshd_config.d
    ```

2. Regarder le contenu de chaque fichier dans le dossier `/etc/ssh/sshd_config.d`
    ```sh
    cat /etc/ssh/sshd_config.d/<nom_fichier>.conf
    ```

3. Si le fichier contient `PasswordAuthentication yes`, renommer le fichier en ajoutant `.ignore` à la fin. Voici un exemple pour le fichier `50-cloud-init.conf`
    ```sh
    sudo mv sshd_config.d/50-cloud-init.conf sshd_config.d/50-cloud-init.conf.ignore
    ```

4. Autoriser les connexions SSH par clés et interdir les connexions SSH par mot de passe. Editer le fichier `/etc/ssh/sshd_config` pour mettre à jour les lignes suivantes, les décommenter si elles sont commentées ou les ajouter à la fin du fichier si elles ne sont pas présentes
    1. `PubkeyAuthentication yes`
    2. `PasswordAuthentication no`
    3. `AuthenticationMethods publickey`

5. Redémarrer le daemon SSHD et le daemon SSH
    ```sh
    sudo systemctl restart sshd && sudo systemctl restart ssh
    ```

### Configurer la double authentification

1. Installer la librairie
    ```sh
    sudo apt install libpam-google-authenticator
    ```

2. Dans le fichier `/etc/pam.d/sshd`
    1. Commenter la ligne suivante en ajoutant un `#` devant comme montré en dessous
        ```diff
        # Standard Un*x authentication.
        -   @include common-auth
        +   # @include common-auth
        ```
    2. Ajouter les lignes suivantes à la fin du fichier `/etc/pam.d/sshd`
        ```
        # 2 Factor Authentication
        auth required pam_google_authenticator.so
        ```

3. Editer le fichier `/etc/ssh/sshd_config` pour mettre à jour la ligne suivante ou la décommenter si elle est commentée
    1. `ChallengeResponseAuthentication yes`

4. Redémarrer le daemon SSHD
    ```sh
    sudo systemctl restart sshd && sudo systemctl restart ssh
    ```

5. Paramétrer la double authentification pour les utilisateurs `prox-i` et `it-sense`
    ```sh
    sudo -u prox-i google-authenticator
    ```
    ```sh
    sudo -u it-sense google-authenticator
    ```
    Répondre aux questions et rentrer les codes demandés :
    1. Do you want authentication tokens to be time-based (y/n) **y**
    2. Scanner le QR code, saisir le code et sauvegarder les informations affichées sur LastPass
    3. Do you want me to update your "/home/user/.google_authenticator" file? (y/n) **y**
    4. Do you want to disallow multiple uses of the same authentication token? (y/n) **y**
    5. Do you want to do so? (y/n) **n**
    6. Do you want to enable rate-limiting? (y/n) **y**

### Renommer le serveur

1. Editer le fichier `/etc/hostname` et remplacer le nom actuel par `pre-prod-prox-i` ou `prod-prox-i` en fonction du serveur.
    ```sh
    sudo vi /etc/hostname
    ```

2. Faire de même dans ce fichier `/etc/hosts`. Remplacer cette ligne `127.0.1.1       vps-3dd65425.vps.ovh.net        vps-3dd65425` par `127.0.1.1       pre-prod-prox-i` (ou `prod-prox-i` en fonction du serveur)
    ```sh
    sudo vi /etc/hosts
    ```

3. Redémarrer le serveur
    ```sh
    sudo reboot
    ```


### Installer les dépendances

1. Mettre à jour les dépendances
    ```sh
    sudo apt-get update && sudo apt-get upgrade
    ```
2. Installer Docker. Suivre les étapes de [ce guide en ligne](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04) (faire les étapes 1 et 2)

3. Ajouter les utilisateurs `ci-cd`, `prox-i` et `it-sense` au groupe `docker`
    ```sh
    sudo usermod -aG docker ci-cd &&
    sudo usermod -aG docker prox-i &&
    sudo usermod -aG docker it-sense
    ```

4. Installer les dépendances nécessaires
    ```sh
    sudo apt-get install jq
    ```
5. Créer une clé SSH en adaptant le label. Appuyer sur entrer pour accepter la configuration par défaut
    ```sh
    sudo su ci-cd
    ```
    ```sh
    ssh-keygen -t ed25519 -a 200 -C "Clé SSH du serveur de pré-prod de #Prox-i"
    ```
    ```sh
    eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519
    ```
    ```sh
    exit
    ```
6. Spécifier la timezone du serveur
    ```sh
    sudo timedatectl set-timezone Pacific/Tahiti
    ```

### Setup fail2ban

1. Installer le paquet
    ```sh
    sudo apt install fail2ban
    ```
2. Démarrer le service
    ```sh
    sudo systemctl start fail2ban
    ```
3. Ajouter au démarrage automatique
    ```sh
    sudo systemctl enable fail2ban
    ```
4. Vérifier que le service est actif
    ```sh
    sudo systemctl status fail2ban
    ```
5. Créer le fichier `/etc/fail2ban/jail.d/custom.conf` et ajouter la config custom
    ```sh
    sudo vi /etc/fail2ban/jail.d/custom.conf
    ```
    ```
    [DEFAULT]
    ignoreip = 167.114.36.33
    findtime = 10m
    bantime = 12h
    maxretry = 3
    ```
6. Redémarrer le service
    ```sh
    sudo systemctl restart fail2ban
    ```

### Setup ufw firewall

1. S'assurer que le firewall n'est pas actif
    ```sh
    sudo ufw disable
    ```
2. Ouvrir les ports SSH (22), HTTP (80), HTTPS (443), et Docker SFTP (2223)
    ```sh
    sudo ufw allow ssh && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 2223/tcp
    ```
3. Démarrer le firewall et accepter l'opération
    ```sh
    sudo ufw enable
    ```
3. Vérifier que le firewall est actif
    ```sh
    sudo ufw status verbose
    ```

### Setup AWS CLI
Nous avons besoin de AWS CLI pour upload les backup sur le storage S3 Wasabi.
1. Télécharger et installer AWS
    ```sh
    sudo apt install unzip
    cd
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm awscliv2.zip
    ```
2. En tant que l'utilisateur `ci-cd`, configurer les accès (renseigner uniquement `AWS Access Key ID` et `AWS Secret Access Key`, laisser le reste vide)
    ```sh
    su ci-cd
    aws configure
    ```
