{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";
  };

  outputs = { self, nixpkgs }: {
    lib = let
      actions = import ./lib/actions.nix {};
      adr = import ./lib/adr.nix {};
      astro = import ./lib/astro.nix {};
      biome = import ./lib/biome.nix {};
      bun = import ./lib/bun.nix {};
      eric = import ./lib/eric.nix {};
      filter = import ./lib/filter.nix;
      s3cmd = import ./lib/s3cmd.nix {};
      sqlite = import ./lib/sqlite.nix {};
      structurizr = import ./lib/structurizr/default.nix {};
      system = import ./lib/system.nix {};
      systemd = import ./lib/systemd.nix {};
      vault = import ./lib/vault.nix { lib = nixpkgs.lib; };
      webserver = import ./lib/webserver.nix {};
    in {
      inherit actions adr bun biome eric filter s3cmd sqlite vault structurizr;
      allSystems = system.allSystems;
      buildAstroWebsite = astro.buildAstroWebsite;
      buildStaticWebserver = webserver.buildStaticWebserver;
      mkStaticWebserverShell = webserver.mkStaticWebserverShell;
      mkStaticWebserverFlake = webserver.mkStaticWebserverFlake;
      systemdServiceRef = systemd.systemdServiceRef;
    };

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
