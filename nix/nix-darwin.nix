{ pkgs, computername, hostname, useremail, username, ... }: {

      users.users.${username}.home = "/Users/${username}";
      networking.hostName = "${hostname}";
      networking.computerName = "${computername}";

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
          pkgs.brave
          pkgs.git
          pkgs.jujutsu
          pkgs.vim
        ];

      home-manager.extraSpecialArgs = { inherit username useremail; };
      home-manager.users.${username} = { pkgs, ... }:
        {
          imports = [ (import ./common.nix) ];

          # Home Manager needs a bit of information about you and the
          # paths it should manage.
          home.username = "${username}";
          home.homeDirectory = "/Users/${username}";
      
          programs.ghostty = {
            enable = true;
            package = pkgs.ghostty-bin;
            settings = {
              background = "#000000";
              custom-shader = builtins.toString (pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/KroneCorylus/ghostty-shader-playground/refs/heads/main/public/shaders/cursor_smear.glsl";
                hash = "sha256-bae6vHLHpVQWUjYiXRx5wwNTVYDcprEQP0TOjXjYuAE=";
              });
              window-decoration = "none";
            };
          };
      
          targets.darwin.defaults = {
            NSGlobalDomain.KeyRepeat = 2;
            "com.apple.desktopservices" = {
              DSDontWriteNetworkStores = true;
              DSDontWriteUSBStores = true;
            };
            "com.apple.dock" = {
              autohide = true;
              orientation = "right";
            };
          };
      
          # This value determines the Home Manager release that your
          # configuration is compatible with. This helps avoid breakage
          # when a new Home Manager release introduces backwards
          # incompatible changes.
          #
          # You can update Home Manager without changing this value. See
          # the Home Manager release notes for a list of state version
          # changes in each release.
          home.stateVersion = "26.05";
      
          # Let Home Manager install and manage itself.
          programs.home-manager.enable = true;
        };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

    }
