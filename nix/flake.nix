{
  description = "";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;

  outputs = { self, nixpkgs }:
    let
      systems = ["x86_64-linux" "aarch64-linux"];
    in
      {
        packages =
          nixpkgs.lib.attrsets.genAttrs systems (system:
            let
              callPackage = nixpkgs.legacyPackages.${system}.callPackage;
            in
              builtins.mapAttrs
                (dirname: _: callPackage ./flake/packages/${dirname}/package.nix { })
                (builtins.readDir ./flake/packages)
          );
      };
}
