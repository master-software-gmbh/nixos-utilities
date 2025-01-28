{ ... }: {
  buildBunDependencies = (pkgs: {
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

  buildBunPackage = (pkgs: dependencies: {
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
}