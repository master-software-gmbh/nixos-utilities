{ lib, pkgs, config, modulesPath, ... }:

with lib; let
  cfg = config.modules.system;
in {
  options.modules.system = {
    stateVersion = mkOption {
      type = types.str;
    };

    timeZone = mkOption {
      type = types.str;
      default = "UTC";
    };

    hostName = mkOption {
      type = types.str;
    };

    sshPort = mkOption {
      type = types.int;
    };

    sshAuthorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    userName = mkOption {
      type = types.str;
      default = "nixos";
    };

    allowedTCPPorts = mkOption {
      type = types.listOf types.int;
      default = [ ];
    };

    ipv4Address = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    ipv6Address = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  config = {
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    time.timeZone = cfg.timeZone;
    system.stateVersion = cfg.stateVersion;

    networking = {
      hostName = cfg.hostName;
      networkmanager.enable = true;

      firewall = {
        enable = true;
        allowedTCPPorts = cfg.allowedTCPPorts;
      };
    };

    users.users = {
      "${cfg.userName}" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        packages = with pkgs; [ htop ];
        openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
      };
    };

    services = {
      openssh = {
        enable = true;
        ports = [ cfg.sshPort ];
        openFirewall = true;
        settings = {
          X11Forwarding = false;
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      fail2ban = {
        enable = true;
        # Temporary patch due to unreleased fix for fail2ban
        # See: https://github.com/fail2ban/fail2ban/commit/2fed408c05ac5206b490368d94599869bd6a056d and https://github.com/fail2ban/fail2ban/commit/50ff131a0fd8f54fdeb14b48353f842ee8ae8c1a
        package = pkgs.fail2ban.overrideAttrs(old: {
          patches = [
            (pkgs.fetchpatch {
              url = "https://github.com/fail2ban/fail2ban/commit/2fed408c05ac5206b490368d94599869bd6a056d.patch";
              hash = "sha256-uyrCdcBm0QyA97IpHzuGfiQbSSvhGH6YaQluG5jVIiI=";
            })
            (pkgs.fetchpatch {
              url = "https://github.com/fail2ban/fail2ban/commit/50ff131a0fd8f54fdeb14b48353f842ee8ae8c1a.patch";
              hash = "sha256-YGsUPfQRRDVqhBl7LogEfY0JqpLNkwPjihWIjfGdtnQ=";
            })
          ];
        });
      };
    };

    security.pam = {
      sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
      };
    };

    systemd.network = {
      enable = true;
      networks."30-wan" = {
        matchConfig.Name = "enp1s0";
        networkConfig.DHCP = if cfg.ipv4Address == null then "ipv4" else "no";
        address = []
          ++ lib.optional (cfg.ipv4Address != null) cfg.ipv4Address
          ++ lib.optional (cfg.ipv6Address != null) cfg.ipv6Address;
        routes = [
          { Gateway = "172.31.1.1"; GatewayOnLink = true; }
          { Gateway = "fe80::1"; }
        ];
      };
    };

    nix = {
      settings.trusted-users = [ cfg.userName ];

      optimise = {
        automatic = true;
        dates = [ "03:00" ];
      };

      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 3d";
      };
    };

    # Hardware configuration

    boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    swapDevices = [
      { device = "/dev/disk/by-label/swap"; }
    ];

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
