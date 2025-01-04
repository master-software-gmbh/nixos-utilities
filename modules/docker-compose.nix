{ config, lib, pkgs, ... }:
let
  cfg = config.services.docker-compose;
  yaml = pkgs.formats.yaml { };
  files = lib.mapAttrs (name: value: {
    content = yaml.generate name value.content;
    backup = value.backup;
  }) cfg.projects;
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

  config = let
    getProjectServiceName = name: "docker-compose-${name}";
    getRestartServiceName = name: "restart-${name}";
    getBackupServiceName = name: "backup-${name}";
    getBackupTimerName = name: "scheduled-backup-${name}";
    backup = import ./backup.nix { inherit pkgs; };
  in {
    # Create a systemd service to run each project
    systemd.services = lib.mkMerge [
      (lib.mapAttrs' (name: value: lib.nameValuePair (getProjectServiceName name) {
        description = "Run Docker Compose project for ${name}";
        after = [ "network.target" "docker.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${value.content} up -d";
          ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${value.content} down";
          ExecStopPost = lib.mkIf value.backup (
            # has a default timeout of 90 seconds
            "${pkgs.systemd}/bin/systemctl start ${getBackupServiceName name}.service"
          );
        };
      }) files)

      # Create a systemd service to restart each project
      (lib.mapAttrs' (name: value: lib.nameValuePair (getRestartServiceName name) {
        description = "Restart systemd service for ${name}";

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart ${getProjectServiceName name}.service";
        };
      }) (lib.filterAttrs (name: value: value.backup) files))

      # Create a systemd service to backup each project
      (lib.mapAttrs' (name: value: lib.nameValuePair (getBackupServiceName name) {
        description = "Execute backup for ${name}";
        path = [ pkgs.gnutar pkgs.gzip ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${backup.script} /var/lib/${name}";
        };
      }) (lib.filterAttrs (name: value: value.backup) files))
    ];

    # Create a systemd timer to run scheduled backups for each project
    systemd.timers = lib.mapAttrs' (name: value: lib.nameValuePair (getBackupTimerName name) {
      description = "Run scheduled backup for ${name}";
      wantedBy = [ "multi-user.target" ];

      timerConfig = {
        Unit = "${getRestartServiceName name}.service";
        OnCalendar = "2:00";
        Persistent = true;
      };
    }) (lib.filterAttrs (name: value: value.backup) files);

    systemd.tmpfiles.rules = lib.mkIf cfg.enable (lib.concatLists (lib.mapAttrsToList (name: value: [
      "d /var/lib/${name} 0755 root root - -"
      "L+ /var/lib/${name}/docker-compose.yaml 0755 root root - ${value.content}"
    ]) files));
  };
}
