{ lib, ... }:
{
  options.masterSoftware.reverseProxy = with lib; {
    enable = mkEnableOption "Enable Reverse Proxy";
    networkName = mkOption {
      type = types.str;
      default = "reverse-proxy";
      description = "Name of the Docker network";
    };
    services = mkOption {
      default = {};
      description = "Services to reverse proxy";
      type = types.listOf (types.submodule {
        options = {
          domain = mkOption {
            type = types.str;
            description = "Domain of the service";
          };
          backends = mkOption {
            description = "Backends to proxy";
            type = types.listOf (types.submodule {
              options = {
                matcher = mkOption {
                  type = types.str;
                  default = "*";
                  description = "Matcher for the backend";
                };

                upstream = mkOption {
                  type = types.str;
                  description = "Upstream for the backend";
                };
              };
            });
          };
        };
      });
    };
  };
}