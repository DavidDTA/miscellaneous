{ pkgs, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      git = {
        executable-path = "${pkgs.git}/bin/git";
      };
    };
  };
}
