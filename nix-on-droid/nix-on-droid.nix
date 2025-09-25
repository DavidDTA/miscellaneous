{ config, lib, pkgs, ... }:

{
  # Simply install just the packages
  environment.packages = with pkgs; [
    bash
    curl
    direnv
    findutils
    git
    gnugrep
    jq
    jujutsu
    nix-search-cli
    openssh
    ps
    tmux

    # Some common stuff that people expect to have
    #procps
    #killall
    #diffutils
    #findutils
    #utillinux
    #tzdata
    #hostname
    #man
    #gnugrep
    #gnupg
    #gnused
    #gnutar
    #bzip2
    #gzip
    #xz
    #zip
    #unzip
  ];

  environment.sessionVariables = {
    EDITOR = "vim";
    SHELL = "bash";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.config = {pkgs, ... }: {
    home.stateVersion = "24.05";
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
      ];
      extraConfig = builtins.readFile(../.vimrc);
    };
  };

  # android-integration.termux-open.enable = true;
  # android-integration.termux-open-url.enable = true;

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  # environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "America/New_York";

}
