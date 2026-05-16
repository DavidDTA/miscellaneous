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
      overlay = final: prev: {
        vimPlugins = prev.vimPlugins // {
          vim-sensible = lib.addUnpackFallback(prev.vimPlugins.vim-sensible);
        };
      };
      lib = {
        addUnpackFallback =
          let
            # The default unpack hook sometimes fails here:
            # https://github.com/NixOS/nixpkgs/blob/6d7ec06d6868ac6d94c371458fc2391ded9ff13d/pkgs/stdenv/generic/setup.sh#L1256
            # with:
            # cp: setting permissions for 'source': No such file or directory
            # It is unclear why, but this workaround produces the same end result
            # We apply it surgically instead of in stdenv directly in order to avoid needing to rebuild everything
            unpackFallback = pkgs.makeSetupHook { name = "unpack-fallback"; } (pkgs.writeText "unpack-fallback.sh" ''
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
          in
          pkg: pkg.overrideAttrs(old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ unpackFallback ];
          });
        mkNixOnDroidConfiguration = {}: nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgs;
          modules = [ ./nix-on-droid.nix ];
          extraSpecialArgs = {
            localpkgs = packages;
          };
        };
      };
      packages =
        builtins.mapAttrs
          (dirname: _: pkgs.callPackage ./packages/${dirname}/package.nix { })
          (builtins.readDir ./packages);
      pkgs = import nixpkgs-unstable {
        overlays = [ overlay ];
      };
    in
      {
        lib = lib;
        packages = packages;
      };
}
