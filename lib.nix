{ ... }:
let
  astro = import ./lib/astro.nix {};
  biome = import ./lib/biome.nix {};
  bun = import ./lib/bun.nix {};
  filter = import ./lib/filter.nix;
  sqlite = import ./lib/sqlite.nix {};
  system = import ./lib/system.nix {};
  systemd = import ./lib/systemd.nix {};
  webserver = import ./lib/webserver.nix {};
  
  lib = {
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
in
  lib
