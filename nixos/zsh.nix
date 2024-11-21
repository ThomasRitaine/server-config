{ pkgs, ... }: {
  home.stateVersion = "24.05";

  home.packages = [
    pkgs.zsh-autocomplete
    pkgs.zsh-you-should-use
  ];

  programs.zsh = {
    enable = true;

    enableCompletion = false;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "zsh-autocomplete";
        src = "${pkgs.zsh-autocomplete}/share/zsh-autocomplete/";
      }
      {
        name = "you-should-use";
        src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/";
      }
    ];

    initExtra = ''
      bindkey "^[[3;5~" kill-word
      bindkey "^H" backward-kill-word
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
