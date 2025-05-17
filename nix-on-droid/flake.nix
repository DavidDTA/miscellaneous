{
  description = "Basic example of Nix-on-Droid system config.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-on-droid }:
    let
      system = "aarch64-linux";
      unstable-overlay = final: prev: with import nixpkgs-unstable {
        inherit system;
      }; {
        inherit jujutsu;
      };
    in
    {
      programs.direnv.enable = true;
      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ unstable-overlay ];
        };
        modules = [ ./nix-on-droid.nix ];
      };
    };
}
