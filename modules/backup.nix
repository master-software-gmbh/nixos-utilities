{ pkgs, ... }:
let
  backupLocation = "/var/lib/backups";
  backupScript = pkgs.writeShellScript "backup" ''
    #!/bin/bash

    if [ $# -ne 1 ]; then
      echo "Usage: $0 <folder-path>"
      exit 1
    fi

    echo "Creating backup for $1"

    folder_path=$1
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    backup_file="${backupLocation}/$(basename ''\${folder_path})_''\${timestamp}.tar.gz"

    if [ ! -d "$folder_path" ]; then
      echo "Error: Directory $folder_path does not exist."
      exit 1
    fi

    tar -czf "$backup_file" -C "$(dirname "$folder_path")" "$(basename "$folder_path")"

    if [ $? -ne 0 ]; then
      echo "Error: Failed to create backup."
      exit 1
    fi

    echo "Backup created at $backup_file"
  '';
in {
  script = backupScript;

  config = {
    systemd.tmpfiles.rules = [
      "d ${backupLocation} 0755 root root - -"
    ];
  };
}
