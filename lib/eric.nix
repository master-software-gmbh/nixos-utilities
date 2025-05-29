{ ... }: {
  buildEric41 = (pkgs: { plugins ? [] }: let
    version = "41.6.2.0";
    sources = {
      "aarch64-darwin" = pkgs.fetchurl {
        url = "https://download.elster.de/download/eric/eric_41/ERiC-${version}-Darwin-universal.jar";
        hash = "sha256-wxfuQOalmWPKG8z4Vc+bGN8R5v0YZCUAH/ZHXs24yQ4=";
      };
      "x86_64-linux" = pkgs.fetchurl {
        url = "https://download.elster.de/download/eric/eric_41/ERiC-${version}-Linux-x86_64.jar";
        hash = "sha256-zHitG4Ktt+iCKk9GrC3C4MRSWhUxh89kW9bUeHzqNJs=";
      };
    };

  in pkgs.stdenvNoCC.mkDerivation {
    name = "eric";
    inherit version;

    nativeBuildInputs = [
      pkgs.unzip
    ];

    src = sources.${pkgs.stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenvNoCC.hostPlatform.system}");

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/plugins2

      # Move files with .so extension for Linux or .dylib extension for macOS
      mv ERiC-${version}/*/lib/libericapi.{so,dylib} $out/
      mv ERiC-${version}/*/lib/libeSigner.{so,dylib} $out/
      mv ERiC-${version}/*/lib/libericxerces.{so,dylib} $out/
      mv ERiC-${version}/*/lib/plugins2/libcommonData.{so,dylib} $out/plugins2/

      for plugin in ${builtins.concatStringsSep " " plugins}; do
        mv ERiC-${version}/*/lib/plugins2/$plugin.{so,dylib} $out/plugins2/
      done
    '';
  });
}
