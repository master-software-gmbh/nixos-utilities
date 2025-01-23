{ config, lib, pkgs, ... }:

let
  cfg = config.masterSoftware.dockerCompose;
  yaml = pkgs.formats.yaml { };
  systemdServiceRef = (import ../lib.nix { inherit pkgs; }).systemdServiceRef;
in {
  imports = [
    ./backups.nix
    ./systemd-timers.nix
  ];

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

  config = {
    systemd = lib.mkIf cfg.enable (lib.mkMerge (lib.mapAttrsToList (name: project: let
      dockerComposeFile = yaml.generate name project.content;
      projectPath = "/var/lib/${name}";
      projectService = "docker-compose-${name}";
      restartService = "restart-${name}";
      backupService = config.masterSoftware.backups.locations."${projectPath}".serviceName;
    in {
      # Create a systemd service to run each project
      services.${projectService} = {
        description = "Run Docker Compose project for ${name}";
        after = [
          "network.target"
          "docker.service"
          (systemdServiceRef config.masterSoftware.vaultAgent.serviceName)
          (systemdServiceRef config.masterSoftware.docker.setupService)
        ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ dockerComposeFile ];

        serviceConfig = let
          startScript = pkgs.writeShellScript "backup" ''
            #!/bin/bash
            ${lib.concatStringsSep "\n" (lib.map (imageName: "${pkgs.docker}/bin/docker image load -i ${imageName}") project.loadImages)}
            ${pkgs.docker-compose}/bin/docker-compose -f ${dockerComposeFile} up -d
          '';
        in {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = startScript;
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

      tmpfiles.rules = [
        "d ${projectPath} 0755 root root - -"
        "L+ ${projectPath}/docker-compose.yaml 0755 root root - ${dockerComposeFile}"
      ];
    }) cfg.projects));

    masterSoftware.backups = lib.mkIf cfg.enable (lib.mkMerge (lib.mapAttrsToList (name: project: {
      # Setup a backup service
      enable = true;
      locations."/var/lib/${name}" = {
        serviceName = "backup-${name}";
      };
    }) (lib.filterAttrs (name: project: project.backup) cfg.projects)));

    masterSoftware.systemdTimers = lib.mkIf cfg.enable (lib.mkMerge (lib.mapAttrsToList (name: project: {
      # Setup a systemd timer
      enable = true;
      timers."scheduled-backup-${name}" = {
        description = "Run scheduled backup of /var/lib/${name}";
        serviceName = "restart-${name}";
      };
    }) (lib.filterAttrs (name: project: project.backup) cfg.projects)));
  };
}
