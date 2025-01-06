{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";
  };

  outputs = { self, nixpkgs }: {
    lib = import ./lib.nix { pkgs = nixpkgs; };
    nixosModules = {
      system = import ./modules/system.nix;
      docker = import ./modules/docker.nix;
      dockerCompose = import ./modules/docker-compose.nix;
      reverseProxy = import ./modules/reverse-proxy.nix;
      caddyReverseProxy = import ./modules/caddy.nix;
    };
  };
}
