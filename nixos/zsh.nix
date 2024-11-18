{ pkgs, ... }: {
  home.stateVersion = "24.05";

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initExtra = ''
      bindkey "''${key[Up]}" up-line-or-search
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      source /opt/terminal/init.sh
    '';

    shellAliases = {
      update = "sudo nixos-rebuild switch";
      vi = "nvim";
    };
  };
}
