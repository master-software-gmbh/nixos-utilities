{ pkgs, lib, config, ... }:
let
  cfg = config.masterSoftware.vaultAgent;
  json = pkgs.formats.json { };
in {
  options = {
    masterSoftware.vaultAgent = with lib; {
      enable = mkEnableOption "Enable vault-agent";
      serviceName = mkOption {
        type = types.str;
        default = "vault-agent";
      };
      agentConfig = mkOption {
        type = json.type;
      };
    };
  };

  config = let
    configFile = pkgs.writeText "agent-config.json" (builtins.toJSON cfg.agentConfig);
  in lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname) [ "vault-bin" ];

    environment = {
      systemPackages = [ pkgs.vault-bin ];
    };

    systemd.services."${cfg.serviceName}" = {
      description = "HashiCorp Vault Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.getent ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.vault-bin}/bin/vault agent -config=${configFile}";
      };
    };
  };
}
