{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";
  };

  outputs = { self, nixpkgs }:
    let
    in {
      lib = import ./lib.nix { inherit nixpkgs; };
      nixosModules = {
        system = import ./modules/system.nix;
        dockerCompose = import ./modules/docker-compose.nix;
        reverseProxy = import ./modules/reverse-proxy.nix;
        caddyReverseProxy = import ./modules/caddy.nix;
      };
    };
}