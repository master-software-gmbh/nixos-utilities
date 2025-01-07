{ config, lib, pkgs, ... }:

let
  cfg = config.masterSoftware.systemdTimers;
  systemdServiceRef = (import ../lib.nix { inherit pkgs; }).systemdServiceRef;
in {
  options = {
    masterSoftware.systemdTimers = with lib; {
      enable = mkEnableOption "Enable systemd timers";
      timers = mkOption {
        default = {};
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options = {
            description = mkOption {
              description = "Description of the systemd timer";
              type = types.str;
            };
            serviceName = mkOption {
              description = "Name of the systemd service to run";
              type = types.str;
            };
            onCalendar = mkOption {
              description = "OnCalendar option for the systemd timer";
              type = types.str;
              default = "2:00";
            };
          };
        }));
      };
    };
  };

  config = {
    systemd = lib.mkMerge (lib.mapAttrsToList (name: options: {
      timers.${name} = {
        description = options.description;
        wantedBy = [ "multi-user.target" ];

        timerConfig = {
          Unit = systemdServiceRef options.serviceName;
          OnCalendar = options.onCalendar;
          Persistent = true;
        };
      };
    }) cfg.timers);
  };
}
