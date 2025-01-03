{ config, lib, pkgs, ... }:
let
  cfg = config.services.docker-compose;
  yaml = pkgs.formats.yaml { };
  files = lib.mapAttrs (name: value: yaml.generate name value.content) cfg.projects;
in {
  options = {
    services.docker-compose = {
      enable = lib.mkEnableOption "Enable Docker Compose";
      projects = lib.mkOption {
        default = {};
        type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
          options = {
            content = lib.mkOption {
              type = yaml.type;
              default = {};
            };
          };
        }));
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = lib.concatLists (lib.mapAttrsToList (name: value: [
      "d /var/lib/${name} 0755 root root - -"
      "L+ /var/lib/${name}/docker-compose.yaml 0755 root root - ${value}"
    ]) files);
  };
}
