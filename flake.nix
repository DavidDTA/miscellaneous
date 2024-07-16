{
  description = "";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      callPackage = nixpkgs.legacyPackages.${system}.callPackage;
      flakePackages =
        builtins.mapAttrs
          (dirname: _: callPackage ./flake/packages/${dirname}/package.nix { })
          (builtins.readDir ./flake/packages);
    in
      {
        packages.${system} = flakePackages;
      };
}
