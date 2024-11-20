{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  swapDevices = [
    { device = "/swapfile"; size = 8192; }
  ];

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
  users.users = {
    root = {
      isNormalUser = false;
      hashedPasswordFile = "/etc/nixos/secrets/root-password";
    };
    thomas = {
      isNormalUser = true;
      description = "Thomas";
      home = "/home/thomas";
      extraGroups = [ "wheel" "docker" ];
      hashedPasswordFile = "/etc/nixos/secrets/thomas-password";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFDBWxSC0X5OEFoc+DK8ZmWrDERNQwGzUNG8261IedI Personal VPS ssh key for user thomas"
      ];
    };
    "app-manager" = {
      isNormalUser = true;
      description = "App Manager";
      home = "/home/app-manager";
      extraGroups = [ "docker" ];
      hashedPasswordFile = "/etc/nixos/secrets/app-manager-password";
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
    awscli2
    jq
    starship
    zsh
    neovim
  ];

  virtualisation.docker.enable = true;

  # ZSH setup
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  environment.pathsToLink = [ "/share/zsh" ];
  home-manager.users.root = { pkgs, ... }: {
    imports = [ ./zsh.nix ];
  };
  home-manager.users.thomas = { pkgs, ... }: {
    imports = [ ./zsh.nix ];
  };
  home-manager.users.app-manager = { pkgs, ... }: {
    imports = [ ./zsh.nix ];
  };

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

  systemd.services.backup = {
    description = "Run the backup script for app-manager";
    serviceConfig = {
      Type = "oneshot";
      User = "app-manager";
      ExecStart = "${pkgs.bash}/bin/bash /home/app-manager/server-config/backup/cron_backup.sh";
      StandardOutput = "append:/home/app-manager/server-config/backup/logs/cron_run.log";
      StandardError = "append:/home/app-manager/server-config/backup/logs/cron_run.log";
    };
    path = with pkgs; [
      docker
      jq
      gnutar
      awscli2
    ];
  };

  systemd.timers.backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:00";
    };
  };
}
