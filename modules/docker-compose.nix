{ config, lib, pkgs, ... }:
let
  cfg = config.services.docker-compose;
  yaml = pkgs.formats.yaml { };
  backup = import ./backup.nix { inherit pkgs; };
in {
  options = {
    services.docker-compose = {
      enable = lib.mkEnableOption "Enable Docker Compose";
      projects = lib.mkOption {
        default = {};
        type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
          options = {
            backup = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            content = lib.mkOption {
              type = yaml.type;
              default = {};
            };
          };
        }));
      };
    };
  };

  config.systemd = lib.mkIf cfg.enable (lib.mkMerge (lib.mapAttrsToList (name: project: let
    dockerComposeFile = yaml.generate name project.content;
    projectServiceName = "docker-compose-${name}";
    restartServiceName = "restart-${name}";
    backupServiceName = "backup-${name}";
    backupTimerName = "scheduled-backup-${name}";
  in {
    # Create a systemd service to run each project
    services.${projectServiceName} = {
      description = "Run Docker Compose project for ${name}";
      after = [ "network.target" "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ dockerComposeFile ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${dockerComposeFile} up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${dockerComposeFile} down";
        ExecStopPost = lib.mkIf project.backup (
          # has a default timeout of 90 seconds
          "${pkgs.systemd}/bin/systemctl start ${backupServiceName}.service"
        );
      };
    };

    # Create a systemd service to restart each project
    services.${restartServiceName} = lib.mkIf project.backup {
      description = "Restart systemd service for ${name}";

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart ${projectServiceName}.service";
      };
    };

    # Create a systemd service to backup each project
    services.${backupServiceName} = lib.mkIf project.backup {
      description = "Execute backup for ${name}";
      path = [ pkgs.gnutar pkgs.gzip pkgs.s3cmd ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${backup.script} /var/lib/${name}";
      };
    };

    # Create a systemd timer to run scheduled backups for each project
    timers.${backupTimerName} = lib.mkIf project.backup {
      description = "Run scheduled backup for ${name}";
      wantedBy = [ "multi-user.target" ];

      timerConfig = {
        Unit = "${restartServiceName}.service";
        OnCalendar = "2:00";
        Persistent = true;
      };
    };

    tmpfiles.rules = [
      "d /var/lib/${name} 0755 root root - -"
      "L+ /var/lib/${name}/docker-compose.yaml 0755 root root - ${dockerComposeFile}"
    ];
  }) cfg.projects));
}
