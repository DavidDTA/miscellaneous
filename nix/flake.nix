{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs-stable, nixpkgs-unstable, nix-on-droid, home-manager }:
    let
      systems = ["x86_64-linux" "aarch64-linux"];
      unstable-overlay = final: prev: with import nixpkgs-unstable { }; {
        inherit jujutsu;
      };
      packages =
        nixpkgs-unstable.lib.attrsets.genAttrs systems (system:
          let
            callPackage = nixpkgs-unstable.legacyPackages.${system}.callPackage;
          in
            builtins.mapAttrs
              (dirname: _: callPackage ./packages/${dirname}/package.nix { })
              (builtins.readDir ./packages)
        );
        pkgs = import nixpkgs-stable {
          overlays = [ unstable-overlay ];
        };
    in
      {
        packages = packages;
        nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgs;
          modules = [ ./nix-on-droid.nix ];
          extraSpecialArgs = {
            localpkgs = packages.${pkgs.stdenv.hostPlatform.system};
          };
        };
      };
}
