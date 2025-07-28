{ config, lib, pkgs, ... }:

let
  cfg = config.masterSoftware.reverseProxy;
  useSecret = cfg.secretName != null;
  dockerNetworkName = cfg.networkName;
  globalOptions = ''
    {
      admin off
    }
  '';
  headers = headers: builtins.concatStringsSep "\n" (map (header: ''
    header_up ${header.name} ${header.value}
  '') headers);
  reverseProxy = backend: if backend.upstream != null then ''
    reverse_proxy ${backend.matcher} {
      to ${backend.upstream}
      ${headers backend.headers}
    }
  '' else if backend.root != null then ''
    root ${backend.matcher} ${backend.root}
    file_server
  '' else "";
  reverseProxies = service: builtins.concatStringsSep "\n" (map (backend: ''
    ${reverseProxy backend}
  '') service.backends);
  basicAuth = service: if service.basicAuth != null then let
    users = builtins.concatStringsSep "\n" (map (user: ''
      ${user.username} ${user.password}
    '') service.basicAuth);
  in ''
    basic_auth {
      ${users}
    }
  '' else "";
  redirect = service: if service.redirect != null then let
    code = if service.redirect.permanent then "permanent" else "temporary";
  in ''
    redir ${service.redirect.matcher} ${service.redirect.destination}{uri} ${code} 
  '' else "";
  site = service: ''
    ${service.domain} {
      header -Server
      encode zstd gzip
      ${redirect service}
      ${basicAuth service}
      ${reverseProxies service}
    }
  '';
  sites = builtins.concatStringsSep "\n" (map (service: ''
    ${site service}
  '') cfg.services);
  secretStart = if useSecret then ''
    {{- with secret "${cfg.secretName}" -}}
  '' else "";
  secretEnd = if useSecret then ''
    {{- end -}}
  '' else "";
  caddyfile = pkgs.writeTextFile {
    name = if useSecret then "Caddyfile.ctmpl" else "Caddyfile";
    text = ''
      ${secretStart}
      ${globalOptions}
      ${sites}
      ${secretEnd}
    '';
  };
in {
  imports = [
    ./reverse-proxy.nix
  ];

  config = lib.mkIf cfg.enable {
    masterSoftware = {
      dockerCompose = {
        enable = true;
        projects.reverse-proxy = {
          backup = true;
          restartTriggers = [ caddyfile ];
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
              ports = lib.mkIf (dockerNetworkName != null) [
                "80:80"
                "443:443"
              ];
              extra_hosts = [
                "host.docker.internal:host-gateway"
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
      vaultAgent = lib.mkIf useSecret {
        agentConfig = {
          template = [
            {
              source = caddyfile;
              destination = "/var/lib/reverse-proxy/Caddyfile";
              create_dest_dirs = true;
            }
          ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/reverse-proxy/data 0755 root root - -"
      "d /var/lib/reverse-proxy/config 0755 root root - -"
    ] ++ (if useSecret then [] else [
      "L+ /var/lib/reverse-proxy/Caddyfile 0755 root root - ${caddyfile}"
    ]);
  };
}