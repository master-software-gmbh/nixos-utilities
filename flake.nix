{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";
  };

  outputs = { self, nixpkgs }:
    let
    in {
      nixosModules = {
        system = import ./modules/system.nix;
        docker-compose = import ./modules/docker-compose.nix;
        reverse-proxy = import ./modules/reverse-proxy.nix;
        caddy-reverse-proxy = import ./modules/caddy.nix;
      };
    };
}