{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";
  };

  outputs = { self, nixpkgs }: {
    lib = import ./lib.nix { pkgs = nixpkgs; };
    nixosModules = {
      backups = import ./modules/backups.nix;
      caddyReverseProxy = import ./modules/caddy.nix;
      docker = import ./modules/docker.nix;
      dockerCompose = import ./modules/docker-compose.nix;
      reverseProxy = import ./modules/reverse-proxy.nix;
      system = import ./modules/system.nix;
      systemdTimers = import ./modules/systemd-timers.nix;
      vaultAgent = import ./modules/vault-agent.nix;
    };
  };
}
