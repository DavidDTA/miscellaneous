{ pkgs, useremail, username, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      git = {
        executable-path = "${pkgs.git}/bin/git";
      };
      user = {
        name = "${username}";
        email = "${useremail}";
      };
    };
  };
}
