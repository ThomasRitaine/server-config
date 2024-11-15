{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
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

  users.mutableUsers = true;
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
    awscli2
    jq
    starship
    zsh
    neovim
  ];

  virtualisation.docker.enable = true;

  environment.etc."opt/terminal" = {
    source = pkgs.fetchgit {
      url = "https://github.com/ThomasRitaine/terminal.git";
      rev = "HEAD";
      sha256 = "sha256-Xd5+eyD6dqi7XiYx3s9lVjeiur1ziPWm7b3iYLdhL0w=";
    };
  };

  environment.etc."home/app-manager/server-config" = {
    source = pkgs.fetchgit {
      url = "https://github.com/ThomasRitaine/server-config.git";
      rev = "HEAD";
      sha256 = "sha256-LU3rKmwRhXMtopYLJJdQHXV96Q/+HKZYf/XCHxfrF3I=";
    };
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

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
  system.userActivationScripts.zshrc = "echo 'source /opt/terminal/init.sh' > ~/.zshrc";

  swapDevices = [
    { device = "/swapfile"; size = 8192; }
  ];

  systemd.tmpfiles.rules = [
    "d /home/app-manager/applications 0755 app-manager app-manager -"
  ];

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
      OnCalendar = "02:00";
    };
  };
}
