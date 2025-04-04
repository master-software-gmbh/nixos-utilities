{ ... }: {
  buildDependencies = (pkgs: {
    pname,
    version,
    src,
    hash ? pkgs.lib.fakeSha256,
    flags ? [],
    key ? null,
  }: let
    configureSSHKey = [
      "TEMP_DIR=$(mktemp -d)"
      "cp ${key} $TEMP_DIR/key.pem"
      "chmod 600 $TEMP_DIR/key.pem"
      "export GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -i $TEMP_DIR/key.pem\""
    ];
  in pkgs.stdenv.mkDerivation {
    inherit version src;

    pname = "${pname}_node-modules";
    nativeBuildInputs = [ pkgs.bun pkgs.openssh pkgs.git ];

    buildPhase = ''
      ${if key != null then builtins.concatStringsSep "\n" configureSSHKey else ""}
      bun install --no-progress --frozen-lockfile --ignore-scripts ${builtins.concatStringsSep " " flags}
      rm -rf node_modules/.cache
    '';

    installPhase = ''
      mkdir -p $out
      mv node_modules $out
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = hash;
  });

  buildPackage = (pkgs: dependencies: {
    pname,
    version,
    src,
    env ? {},
  }: pkgs.stdenv.mkDerivation {
      inherit pname version src;
      nativeBuildInputs = [ pkgs.bun dependencies pkgs.makeWrapper ];

      installPhase = let
        envFlags = builtins.concatStringsSep " " (pkgs.lib.mapAttrsToList (name: value: "--set ${name} ${value}") env);
      in ''
        mkdir -p $out
        ln -s ${dependencies}/node_modules $out/
        cp -R . $out
        makeWrapper ${pkgs.bun}/bin/bun $out/bun --chdir $out ${envFlags}
        makeWrapper ${pkgs.bun}/bin/bun $out/run --chdir $out ${envFlags} --add-flags "run --prefer-offline --no-install $out/src/main.ts"
        makeWrapper ${pkgs.bun}/bin/bunx $out/bunx --chdir $out ${envFlags}
      '';
  });

  overlay1_2_8 = system: (final: prev: let
    version = "1.2.8";
  in {
    bun = prev.bun.overrideAttrs (old: {
      inherit version;
      src = {
        "aarch64-darwin" = prev.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-aarch64.zip";
          hash = "sha256-ioBqQKA3Mp5PtVlFcmf2xOvoIEy7rNsD85s0m+1ao1U=";
        };
        "aarch64-linux" = prev.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-aarch64.zip";
          hash = "sha256-Iwg/JW8qHRVcRW4S45xR4x3EG5fGNCDZkV9Du4ar6rE=";
        };
        "x86_64-darwin" = prev.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-x64-baseline.zip";
          hash = "sha256-vYcbm19aR540MrO4YFQgeSwNOKLot8/H03i0NP8c2og=";
        };
        "x86_64-linux" = prev.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
          hash = "sha256-QrSLNmdguYb+HWqLE8VwbSZzCDmoV3eQzS6PKHmenzE=";
        };
      }.${system};

      sourceRoot = {
        aarch64-darwin = "bun-darwin-aarch64";
        x86_64-darwin = "bun-darwin-x64-baseline";
      }.${system} or null;
    });
  });
}