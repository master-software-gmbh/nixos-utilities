{ pkgs, lib, config, ... }:
let
  cfg = config.masterSoftware.vaultAgent;
  json = pkgs.formats.json { };
in {
  options = {
    masterSoftware.vaultAgent = {
      enable = lib.mkEnableOption "Enable vault-agent";
      agentConfig = lib.mkOption {
        type = json.type;
      };
    };
  };

  config = let
    configFile = pkgs.writeText "agent-config.json" (builtins.toJSON cfg.agentConfig);
  in lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname) [ "vault" ];

    environment = {
      systemPackages = [ pkgs.vault ];
    };

    systemd.services = {
      vault-agent = {
        description = "HashiCorp Vault Agent";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        path = [ pkgs.getent ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.vault}/bin/vault agent -config=${configFile}";
        };
      };
    };
  };
}
