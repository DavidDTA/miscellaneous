{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
      overlay = final: prev: 
        let
          # The default unpack hook sometimes fails here:
          # https://github.com/NixOS/nixpkgs/blob/6d7ec06d6868ac6d94c371458fc2391ded9ff13d/pkgs/stdenv/generic/setup.sh#L1256
          # with:
          # cp: setting permissions for 'source': No such file or directory
          # It is unclear why, but this workaround produces the same end result
          # We apply it surgically instead of in stdenv directly in order to avoid needing to rebuild everything
          unpackFallback = prev.makeSetupHook { name = "unpack-fallback"; } (prev.writeText "unpack-fallback.sh" ''
            _unpackFallback() {
              local fn="$1"
         
              if [ ! -d "$fn" ]; then
                return 1
              fi
         
              local destination="$(stripHash "$fn")"
              if [ -e "$destination" ]; then
                echo "Cannot copy $fn to $destination: destination already exists!"
                return 1
              fi
         
              mkdir "$destination"
              cp -r --preserve=timestamps --reflink=auto -- "$fn"/* "$destination"
            }
         
            unpackCmdHooks+=(_unpackFallback)
          '');
          addUnpackFallback = pkg: pkg.overrideAttrs(old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ unpackFallback ];
          });
        in
        {
        vimPlugins = prev.vimPlugins // {
          vim-sensible = addUnpackFallback(prev.vimPlugins.vim-sensible);
        };
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
      pkgs = import nixpkgs-unstable {
        overlays = [ overlay ];
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
