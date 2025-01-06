{ pkgs, ... }:
let
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  allSystems = pkgs.lib.genAttrs systems;

  buildBunDependencies = (pkgs: {
    pname,
    version,
    src,
    hash,
  }: pkgs.stdenv.mkDerivation {
    pname = "${pname}_node-modules";
    inherit version src;

    nativeBuildInputs = [ pkgs.bun ];
    buildPhase = ''
      bun install --production --no-progress --frozen-lockfile
    '';

    installPhase = ''
      mkdir -p $out/node_modules
      cp -R ./node_modules/* $out/node_modules
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = hash;
  });

  buildBunPackage = (pkgs: {
    pname,
    version,
    src,
    hash,
  }:
    let
      nodeModules = buildBunDependencies pkgs { inherit pname version src hash; };
    in pkgs.stdenv.mkDerivation {
      inherit pname version src;
      nativeBuildInputs = [ pkgs.bun nodeModules pkgs.makeBinaryWrapper ];

      installPhase = ''
        mkdir -p $out/
        ln -s ${nodeModules}/node_modules $out/
        cp -R ./src package.jso[n] tsconfig.jso[n] $out

        makeBinaryWrapper ${pkgs.bun}/bin/bun $out/bin \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bun ]} \
          --add-flags "run --prefer-offline --no-install $out/src/main.ts"
      '';
  });

  systemdServiceRef = name: "${name}.service";

  lib = {
    inherit allSystems;
    inherit buildBunDependencies;
    inherit buildBunPackage;
    inherit systemdServiceRef;
  };
in
  lib
