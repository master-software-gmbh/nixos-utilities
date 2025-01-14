{ config, lib, pkgs, ... }:

let
  cfg = config.masterSoftware.backups;
  backupLocation = "/var/lib/backups";
  optionalS3Backup = if (cfg.s3Config.configFile != null) then ''
    ${pkgs.s3cmd}/bin/s3cmd --config=${cfg.s3Config.configFile} put $backup_file s3://${cfg.s3Config.bucket}

    if [ $? -ne 0 ]; then
      echo "Failed to create S3 backup."
      exit 1
    fi
  '' else "";
  backupScript = backupPath: (pkgs.writeShellScript "backup" ''
    #!/bin/bash

    folder_path=${backupPath}

    echo "Creating backup from $1."

    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    backup_file="${backupLocation}/$(basename ''\${folder_path})_''\${timestamp}.tar.gz"

    if [ ! -d "$folder_path" ]; then
      echo "Directory $folder_path does not exist."
      exit 1
    fi

    tar -czf "$backup_file" -C "$(dirname "$folder_path")" --dereference "$(basename "$folder_path")"

    if [ $? -ne 0 ]; then
      echo "Failed to create local backup."
      exit 1
    fi

    ${optionalS3Backup}

    echo "Backup created at $backup_file."
  '');
in {
  options = {
    masterSoftware.backups = with lib; {
      enable = mkEnableOption "Enable backups";
      s3Config = mkOption {
        description = "Configuration object for optional S3 backup";
        default = null;
        type = types.nullOr (types.submodule {
          options = {
            bucket = mkOption {
              description = "S3 bucket";
              type = types.str;
            };
            configFile = mkOption {
              description = "Path to the s3cmd configuration file";
              type = types.str;
            };
          };
        });
      };
      locations = mkOption {
        default = {};
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options = {
            serviceName = mkOption {
              description = "Name of the systemd backup service";
              type = types.str;
              default = "backup${name}";
            };
            preCommand = mkOption {
              description = "Command to run before the backup";
              type = types.nullOr types.str;
              default = null;
            };
            postCommand = mkOption {
              description = "Command to run after the backup";
              type = types.nullOr types.str;
              default = null;
            };
          };
        }));
      };
    };
  };

  config = {
    environment.systemPackages = [ pkgs.gnupg pkgs.gnutar pkgs.gzip pkgs.s3cmd ];

    systemd = lib.mkMerge [
      {
        tmpfiles.rules = [
          "d ${backupLocation} 0755 root root - -"
        ];
      }

      (lib.mkMerge (lib.mapAttrsToList (path: options: let
        script = backupScript path;
      in {
        services."${options.serviceName}" = {
          description = "Execute backup of ${path}";
          path = [ pkgs.gnutar pkgs.gzip pkgs.s3cmd ];

          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = lib.mkIf (options.preCommand != null) options.preCommand;
            ExecStart = script;
            ExecStartPost = lib.mkIf (options.postCommand != null) options.postCommand;
          };
        };
      }) cfg.locations))
    ];
  };
}
