{ ... }: {
  buildEric41 = (pkgs: { plugins ? [] }: pkgs.stdenv.mkDerivation {
    name = "eric";
    version = "41.5.4";

    nativeBuildInputs = [
      pkgs.unzip
    ];

    src = pkgs.fetchurl {
      url = https://download.elster.de/download/eric/eric_41/ERiC-41.5.4.0-Linux-x86_64.jar;
      sha256 = "sha256-8GZfBYOC6gfFmIV1B2QuklEDadA4XrsYYyryCcAg8h0=";
    };

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/plugins2

      mv ERiC-41.5.4.0/Linux-x86_64/lib/libericapi.so $out/
      mv ERiC-41.5.4.0/Linux-x86_64/lib/libeSigner.so $out/
      mv ERiC-41.5.4.0/Linux-x86_64/lib/libericxerces.so $out/
      mv ERiC-41.5.4.0/Linux-x86_64/lib/plugins2/libcommonData.so $out/plugins2/

      for plugin in ${builtins.concatStringsSep " " plugins}; do
        mv ERiC-41.5.4.0/Linux-x86_64/lib/plugins2/$plugin.so $out/plugins2/
      done
    '';
  });
}
