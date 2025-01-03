{ nixpkgs }:
let
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  allSystems = nixpkgs.lib.genAttrs systems;

  lib = {
    inherit allSystems;
  };
in
  lib
