{ lib, ... }:

{
  options.masterSoftware.reverseProxy = with lib; {
    enable = mkEnableOption "Enable Reverse Proxy";
    secretName = mkOption {
      description = "Name of the Vault secret";
      type = types.nullOr types.str;
      default = null;
    };
    networkName = mkOption {
      description = "Name of the Docker network. If the value is null, the host network will be used.";
      type = types.nullOr types.str;
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
            default = [];
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
          redirect = mkOption {
            description = "Redirect to another domain";
            default = null;
            type = types.nullOr (types.submodule {
              options = {
                destination = mkOption {
                  description = "Domain to redirect to";
                  type = types.str;
                };
                permanent = mkOption {
                  description = "Use a permanent redirect";
                  type = types.bool;
                  default = false;
                };
              };
            });
          };
          basicAuth = mkOption {
            description = "Basic authentication";
            default = null;
            type = types.nullOr (types.listOf (types.submodule {
              options = {
                username = mkOption {
                  description = "Username";
                  type = types.str;
                };
                password = mkOption {
                  description = "Password hash";
                  type = types.str;
                };
              };
            }));
          };
        };
      });
      default = {};
    };
  };
}