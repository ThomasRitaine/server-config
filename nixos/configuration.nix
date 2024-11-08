{ config, pkgs, ... }:

let
  # Fetch the terminal configuration repository
  terminalRepo = pkgs.fetchFromGitHub {
    owner = "ThomasRitaine";
    repo = "terminal";
    rev = "main";
    sha256 = "13n0w13qldjwl6hvn61ypnyg6hxgqrv8pd6bp1m48awcxlk06483";
  };

  # Package the terminal configuration for installation
  terminalConfig = pkgs.stdenv.mkDerivation {
    name = "terminal-config";
    src = terminalRepo;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/opt/terminal
      cp -r $src/* $out/opt/terminal/
    '';
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader settings for ARM64
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "vps-8karm";

  # Timezone and locale
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "fr";

  # Networking and firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowPing = false;
  };

  # SSH configuration
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    challengeResponseAuthentication = false;
  };

  # Users configuration
  users.mutableUsers = false;  # Ensure users are managed declaratively
  users.users = {
    thomas = {
      isNormalUser = true;
      description = "Thomas";
      home = "/home/thomas";
      extraGroups = [ "wheel" "docker" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        # Replace this with the actual public key
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... the public key ..."
      ];
    };
    "app-manager" = {
      isNormalUser = true;
      description = "App Manager";
      home = "/home/app-manager";
      extraGroups = [ "docker" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        # Replace this with the actual public key
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... the public key ..."
      ];
    };
  };

  # Require password for sudo
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # System packages to install
  environment.systemPackages = with pkgs; [
    git
    docker
    docker-compose
    awscli2
    jq
    zsh
    starship
    terminalConfig
  ];

  # Enable Docker service
  virtualisation.docker = {
    enable = true;
  };

  # Enable fail2ban
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

  # Zsh and shell configuration
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "zsh-autosuggestions" "you-should-use" "zsh-syntax-highlighting" ];
    };
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;

    interactiveShellInit = ''
      # Load aliases and Starship from my personal terminal repo
      export TERMINAL_REPO_DIR="/opt/terminal"
      if [ -d "$TERMINAL_REPO_DIR" ]; then
          source "$TERMINAL_REPO_DIR/init.sh"
      fi
    '';
  };

  # Enable Starship prompt
  programs.starship = {
    enable = true;
  };

  # Swap space configuration (optional)
  swapDevices = [
    { device = "/swapfile"; size = 8192; }  # 8GB swap file
  ];

  # Activation script to clone the server-config repository
  system.activationScripts.cloneServerConfig.text = ''
    if [ ! -d /home/app-manager/server-config ]; then
      echo "Cloning server-config repository..."
      mkdir -p /home/app-manager
      chown app-manager:app-manager /home/app-manager
      sudo -u app-manager git clone https://github.com/ThomasRitaine/server-config.git /home/app-manager/server-config
    fi
  '';
}
