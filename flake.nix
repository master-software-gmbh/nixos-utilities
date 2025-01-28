{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11-small";
  };

  outputs = { self, nixpkgs }: {
    lib = let
      astro = import ./lib/astro.nix {};
      biome = import ./lib/biome.nix {};
      bun = import ./lib/bun.nix {};
      filter = import ./lib/filter.nix;
      sqlite = import ./lib/sqlite.nix {};
      system = import ./lib/system.nix {};
      systemd = import ./lib/systemd.nix {};
      webserver = import ./lib/webserver.nix {};
    in {
      inherit biome filter;
      allSystems = system.allSystems;
      buildBunDependencies = bun.buildBunDependencies;
      buildBunPackage = bun.buildBunPackage;
      buildSqliteExtensions = sqlite.buildSqliteExtensions;
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
