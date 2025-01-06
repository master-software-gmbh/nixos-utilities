{ config, lib, pkgs, ... }:

let
  cfg = config.masterSoftware.docker;
  setupNetwork = network: "${pkgs.docker}/bin/docker network inspect ${network} > /dev/null 2>&1 || ${pkgs.docker}/bin/docker network create ${network}";
  setupNetworks = ''
    ${lib.concatStringsSep " " (lib.map (network: setupNetwork network) cfg.networks)}
  '';
  setupScript = ''
    ${setupNetworks}
  '';
in {
  options = {
    masterSoftware.docker = {
      enable = lib.mkEnableOption "Enable Docker";
      users = lib.mkOption {
        description = "Users to add to the docker group";
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      networks = lib.mkOption {
        description = "Docker networks";
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      setupService = lib.mkOption {
        description = "Systemd service to setup Docker";
        type = lib.types.str;
        default = "docker-setup";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
    };

    users.users = lib.mkMerge (lib.map (user: {
      "${user}" = {
        extraGroups = [ "docker" ];
      };
    }) cfg.users);

    systemd.services.${cfg.setupService} = {
      description = "Setup Docker";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      script = setupScript;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
