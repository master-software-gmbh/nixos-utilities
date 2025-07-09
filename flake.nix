{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";
  };

  outputs = { self, nixpkgs }: {
    lib = let
      system = import ./lib/system.nix {};
      systemd = import ./lib/systemd.nix {};
    in {
      adr = import ./lib/adr.nix {};
      bun = import ./lib/bun.nix {};
      allSystems = system.allSystems;
      filter = import ./lib/filter.nix;
      astro = import ./lib/astro.nix {};
      biome = import ./lib/biome.nix {};
      s3cmd = import ./lib/s3cmd.nix {};
      sqlite = import ./lib/sqlite.nix {};
      actions = import ./lib/actions.nix {};
      eric = import ./lib/eric/default.nix {};
      opentofu = import ./lib/opentofu.nix {};
      webserver = import ./lib/webserver.nix {};
      systemdServiceRef = systemd.systemdServiceRef;
      vault = import ./lib/vault.nix { lib = nixpkgs.lib; };
      structurizr = import ./lib/structurizr/default.nix {};
    };

    nixosModules = {
      system = import ./modules/system.nix;
      docker = import ./modules/docker.nix;
      backups = import ./modules/backups.nix;
      vaultAgent = import ./modules/vault-agent.nix;
      caddyReverseProxy = import ./modules/caddy.nix;
      reverseProxy = import ./modules/reverse-proxy.nix;
      dockerCompose = import ./modules/docker-compose.nix;
      systemdTimers = import ./modules/systemd-timers.nix;
    };
  };
}
