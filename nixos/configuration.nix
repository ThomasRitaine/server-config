{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "vps-8karm";

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "fr";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowPing = false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      ChallengeResponseAuthentication = false;
    };
  };

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  users.users = {
    thomas = {
      isNormalUser = true;
      description = "Thomas";
      home = "/home/thomas";
      extraGroups = [ "wheel" "docker" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFDBWxSC0X5OEFoc+DK8ZmWrDERNQwGzUNG8261IedI Personal VPS ssh key for user thomas"
      ];
    };
    "app-manager" = {
      isNormalUser = true;
      description = "App Manager";
      home = "/home/app-manager";
      extraGroups = [ "docker" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhhJyyQRqM+Bq7vBrzwrZIr1hnEbmfrzYXU5kXHIMCm Personal VPS ssh key for user app-manager"
      ];
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  environment.systemPackages = with pkgs; [
    git
    docker
    docker-compose
    awscli2
    jq
    starship
    zsh
  ];

  virtualisation.docker.enable = true;

  services.fail2ban = {
    enable = true;
    jails = {
      sshd = {
        enabled = true;
        settings = {
          port = "ssh";
          filter = "sshd";
          logpath = "/var/log/auth.log";
          maxretry = "5";
        };
      };
    };
  };

  programs.zsh = {
    enable = true;
    promptInit = "";

    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "aws"
        "zsh-autosuggestions"
        "you-should-use"
        "zsh-syntax-highlighting"
      ];
    };

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    interactiveShellInit = ''
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/

      ZSH_THEME="robbyrussell"
      plugins=(
        aws
        zsh-autosuggestions
        you-should-use
        zsh-syntax-highlighting
      )

      source $ZSH/oh-my-zsh.sh


      #====================================
      #======== LOAD CUSTOM CONFIG ========
      #====================================

      # Load aliases and Starship from my personal terminal repo
      export TERMINAL_REPO_DIR="/opt/terminal"
      if [ -d "$TERMINAL_REPO_DIR" ]; then
        source "$TERMINAL_REPO_DIR/init.sh"
      fi
    '';
  };

  swapDevices = [
    { device = "/swapfile"; size = 8192; }
  ];

  system.activationScripts.cloneTerminalRepo.text = ''
    if [ ! -d /opt/terminal ]; then
      echo "Cloning terminal repository to /opt/terminal..."
      ${pkgs.git}/bin/git clone https://github.com/ThomasRitaine/terminal.git /opt/terminal
      chown -R root:root /opt/terminal
      chmod -R 755 /opt/terminal
    fi
  '';

  system.activationScripts.cloneServerConfig.text = ''
    if [ ! -d /home/app-manager/server-config ]; then
      echo "Cloning server-config repository..."
      mkdir -p /home/app-manager
      ${pkgs.git}/bin/git clone https://github.com/ThomasRitaine/server-config.git /home/app-manager/server-config
      chown -R app-manager:app-manager /home/app-manager
    fi
  '';

  systemd.tmpfiles.rules = [
    "d /home/app-manager/applications 0755 app-manager app-manager -"
  ];

  services.logrotate = {
    enable = true;
    settings = {
      header = {
        missingok = true;
        notifempty = true;
        compress = true;
        daily = true;
        rotate = 7;
      };

      "/home/app-manager/applications/*/logs/*.log" = {
        su = "app-manager app-manager";
        rotate = 7;
        compress = true;
        notifempty = true;
        copytruncate = true;
      };

      "/home/app-manager/server-config/traefik/logs/*.log" = {
        su = "app-manager app-manager";
        rotate = 7;
        compress = true;
        notifempty = true;
        copytruncate = true;
      };
    };
  };

  systemd.services.backup = {
    description = "Run the backup script for app-manager";
    serviceConfig = {
      Type = "oneshot";
      User = "app-manager";
      ExecStart = "${pkgs.bash}/bin/bash /home/app-manager/server-config/backup/cron_backup.sh";
      StandardOutput = "append:/home/app-manager/server-config/backup/logs/cron_run.log";
      StandardError = "append:/home/app-manager/server-config/backup/logs/cron_run.log";
    };
  };

  systemd.timers.backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
