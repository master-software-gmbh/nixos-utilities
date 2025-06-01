{ ... }: {
  testCertificate = (pkgs: pkgs.copyPathToStore ./test-softorg-pse.pfx);
  buildEric41 = (pkgs: { extraPlugins ? [], extraSchemas ? [] }: let
    name = "eric";
    version = "41.6.2.0";
    schemas = [
      "ElsterBasisSchema"
    ] ++ extraSchemas;
    plugins = [
      "libcommonData"
    ] ++ extraPlugins;
    sources = {
      "aarch64-darwin" = pkgs.fetchurl {
        url = "https://download.elster.de/download/eric/eric_41/ERiC-${version}-Darwin-universal.jar";
        hash = "sha256-wxfuQOalmWPKG8z4Vc+bGN8R5v0YZCUAH/ZHXs24yQ4=";
      };
      "x86_64-linux" = pkgs.fetchurl {
        url = "https://download.elster.de/download/eric/eric_41/ERiC-${version}-Linux-x86_64.jar";
        hash = "sha256-15y8NekqWFCEC4SuS7YW9uv/NmAzSR/m2CxVNDvPcvo=";
      };
    };
    ericSource = sources.${pkgs.stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenvNoCC.hostPlatform.system}");
    docsSource = pkgs.fetchurl {
      url = "https://download.elster.de/download/eric/eric_41/ERiC-${version}-Dokumentation.zip";
      hash = "sha256-AbsJWLoQmfD1uoPZIfFxcMmrGYW8XbvIfi7Sk8zrbms=";
    };
  in pkgs.stdenvNoCC.mkDerivation {
    inherit name version;

    nativeBuildInputs = [
      pkgs.unzip
    ];

    srcs = [
      ericSource
      docsSource
    ];

    unpackPhase = ''
      for src in $srcs; do
        unzip $src
      done
    '';

    installPhase = ''
      mkdir -p $out/plugins2

      # Move files with .so extension for Linux or .dylib extension for macOS
      mv ERiC-${version}/*/lib/libericapi.{so,dylib} $out/
      mv ERiC-${version}/*/lib/libeSigner.{so,dylib} $out/
      mv ERiC-${version}/*/lib/libericxerces.{so,dylib} $out/

      for plugin in ${builtins.concatStringsSep " " plugins}; do
        mv ERiC-${version}/*/lib/plugins2/$plugin.{so,dylib} $out/plugins2/
      done

      for schema in ${builtins.concatStringsSep " " schemas}; do
        mkdir -p $out/Schnittstellenbeschreibungen/$schema/Schema
        mv ERiC-${version}/Dokumentation/Schnittstellenbeschreibungen/$schema/Schema/*.xsd $out/Schnittstellenbeschreibungen/$schema/Schema/
      done
    '';
  });
}
