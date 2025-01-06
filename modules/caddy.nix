{ config, lib, pkgs, ... }:

let
  cfg = config.masterSoftware.reverseProxy;
  dockerNetworkName = cfg.networkName;
  globalOptions = ''
    {
      admin off
    }
  '';
  reverseProxy = backend: ''
    reverse_proxy ${backend.matcher} {
      to ${backend.upstream}
    }
  '';
  reverseProxies = service: builtins.concatStringsSep "\n" (map (backend: ''
    ${reverseProxy backend}
  '') service.backends);
  site = service: ''
    ${service.domain} {
      header -Server
      ${reverseProxies service}
    }
  '';
  sites = builtins.concatStringsSep "\n" (map (service: ''
    ${site service}
  '') cfg.services);
  caddyfile = pkgs.writeTextFile {
    name = "Caddyfile";
    text = ''
      ${globalOptions}
      ${sites}
    '';
  };
in {
  imports = [
    ./reverse-proxy.nix
  ];

  config = {
    masterSoftware.dockerCompose = {
      enable = true;
      projects.reverse-proxy = {
        backup = true;
        content = {
          name = "reverse-proxy";
          networks.reverse-proxy = lib.mkIf (dockerNetworkName != null) {
            name = dockerNetworkName;
            external = true;
          };
          services.caddy = {
            init = true;
            restart = "unless-stopped";
            image = "caddy:2.8-alpine";
            ports = [
              "80:80"
              "443:443"
            ];
            network_mode = lib.mkIf (dockerNetworkName == null) "host";
            networks = lib.mkIf (dockerNetworkName != null) [ dockerNetworkName ];
            volumes = [
              "/var/lib/reverse-proxy/Caddyfile:/etc/caddy/Caddyfile"
              "/var/lib/reverse-proxy/data:/data/caddy"
              "/var/lib/reverse-proxy/config:/config/caddy"
            ];
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/reverse-proxy/data 0755 root root - -"
      "d /var/lib/reverse-proxy/config 0755 root root - -"
      "L+ /var/lib/reverse-proxy/Caddyfile 0755 root root - ${caddyfile}"
    ];
  };
}