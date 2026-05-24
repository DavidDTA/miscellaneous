{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    # pinned due to https://github.com/nix-community/nix-on-droid/issues/495
    nixpkgs-pinned.url = "github:NixOS/nixpkgs/88d3861acdd3d2f0e361767018218e51810df8a1";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-pinned";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs-stable, nixpkgs-pinned, nix-on-droid, home-manager }:
    {
      mkLib = mkArgs:
        let
          args = if builtins.isFunction mkArgs then mkArgs { inherit nixpkgs miscpkgs lib; } else mkArgs;

          nixpkgs = import nixpkgs-pinned {
            config = args.nixpkgs.config or {};
            overlays = [
              (final: prev: {
                vimPlugins = prev.vimPlugins // {
                  vim-sensible = addUnpackFallback(prev.vimPlugins.vim-sensible);
                };
              })
            ] ++ args.nixpkgs.overlays or [];
          };
          miscpkgs = self.mkPackages { inherit nixpkgs; };
          addUnpackFallback =
            let
              # The default unpack hook sometimes fails here:
              # https://github.com/NixOS/nixpkgs/blob/6d7ec06d6868ac6d94c371458fc2391ded9ff13d/pkgs/stdenv/generic/setup.sh#L1256
              # with:
              # cp: setting permissions for 'source': No such file or directory
              # It is unclear why, but this workaround produces the same end result
              # We apply it surgically instead of in stdenv directly in order to avoid needing to rebuild everything
              unpackFallback = nixpkgs.makeSetupHook { name = "unpack-fallback"; } (nixpkgs.writeText "unpack-fallback.sh" ''
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
          lib = {
            inherit addUnpackFallback;
            mkNixOnDroidConfiguration = {
              modules ? []
            }: nix-on-droid.lib.nixOnDroidConfiguration {
              pkgs = nixpkgs;
              modules = [ ./nix-on-droid.nix ] ++ modules;
              extraSpecialArgs = { inherit miscpkgs; };
            };
          };
        in
        lib;
      mkPackages = { nixpkgs }:
        builtins.mapAttrs
          (dirname: _: nixpkgs.callPackage ./packages/${dirname}/package.nix { })
          (builtins.readDir ./packages);
    };
}
