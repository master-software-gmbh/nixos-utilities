{ config, lib, pkgs, ... }:

let
  cfg = config.masterSoftware.dockerCompose;
  yaml = pkgs.formats.yaml { };
  backup = import ./backup.nix { inherit pkgs; };
  systemdServiceRef = (import ../lib.nix { inherit pkgs; }).systemdServiceRef;
in {
  options = {
    masterSoftware.dockerCompose = {
      enable = lib.mkEnableOption "Enable Docker Compose";
      projects = lib.mkOption {
        default = {};
        type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
          options = {
            backup = lib.mkOption {
              description = "Enable automatic backups for the project directory";
              type = lib.types.bool;
              default = false;
            };
            loadImages = lib.mkOption {
              description = "List of Docker images to load before starting the project";
              type = lib.types.listOf lib.types.str;
              default = [];
            };
            content = lib.mkOption {
              description = "Docker Compose project configuration";
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
    loadImagesService = "load-images-${name}";
    projectService = "docker-compose-${name}";
    restartService = "restart-${name}";
    backupService = "backup-${name}";
    backupTimer = "scheduled-backup-${name}";
  in {
    # Create a systemd service to load images for each project
    services.${loadImagesService} = lib.mkIf (project.loadImages != []) {
      description = "Load Docker images for ${name}";
      after = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ dockerComposeFile ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${lib.concatStringsSep " " (lib.map (imageName: "${pkgs.docker}/bin/docker image load -i ${imageName}") project.loadImages)}
        '';
      };
    };

    # Create a systemd service to run each project
    services.${projectService} = {
      description = "Run Docker Compose project for ${name}";
      after = [ "network.target" "docker.service" (systemdServiceRef loadImagesService) (systemdServiceRef config.masterSoftware.docker.setupService) ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ dockerComposeFile ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${dockerComposeFile} up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${dockerComposeFile} down";
        ExecStopPost = lib.mkIf project.backup (
          # has a default timeout of 90 seconds
          "${pkgs.systemd}/bin/systemctl start ${systemdServiceRef backupService}"
        );
      };
    };

    # Create a systemd service to restart each project
    services.${restartService} = lib.mkIf project.backup {
      description = "Restart systemd service for ${name}";

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart ${systemdServiceRef projectService}";
      };
    };

    # Create a systemd service to backup each project
    services.${backupService} = lib.mkIf project.backup {
      description = "Execute backup for ${name}";
      path = [ pkgs.gnutar pkgs.gzip pkgs.s3cmd ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${backup.script} /var/lib/${name}";
      };
    };

    # Create a systemd timer to run scheduled backups for each project
    timers.${backupTimer} = lib.mkIf project.backup {
      description = "Run scheduled backup for ${name}";
      wantedBy = [ "multi-user.target" ];

      timerConfig = {
        Unit = systemdServiceRef restartService;
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
