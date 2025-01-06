{ lib, ... }:

{
  options.masterSoftware.reverseProxy = with lib; {
    enable = mkEnableOption "Enable Reverse Proxy";
    networkName = mkOption {
      description = "Name of the Docker network";
      type = types.str;
      default = "reverse-proxy";
    };
    services = mkOption {
      description = "Services to reverse proxy";
      type = types.listOf (types.submodule {
        options = {
          domain = mkOption {
            description = "Domain of the service";
            type = types.str;
          };
          backends = mkOption {
            description = "Backends to proxy";
            type = types.listOf (types.submodule {
              options = {
                matcher = mkOption {
                  description = "Matcher for the backend";
                  type = types.str;
                  default = "*";
                };

                upstream = mkOption {
                  description = "Upstream for the backend";
                  type = types.str;
                };
              };
            });
          };
        };
      });
      default = {};
    };
  };
}