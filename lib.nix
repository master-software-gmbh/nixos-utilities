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

  buildSqliteExtensions = (pkgs: path: let
    compileExtension = if (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") then "dylib" else "so";
    compileFlag = if (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") then "-dynamiclib" else "-shared";
  in pkgs.stdenv.mkDerivation {
    name = "sqlite-extensions";
    nativeBuildInputs = [ pkgs.sqlite pkgs.gcc ];
    src = path;

    buildPhase = ''
      for file in *.c; do
        gcc -fPIC ${compileFlag} $file -o ''\${file%.c}.${compileExtension}
      done
    '';

    installPhase = ''
      mkdir -p $out
      cp *.${compileExtension} $out
    '';
  });

  systemdServiceRef = name: "${name}.service";

  lib = {
    inherit allSystems;
    inherit buildBunDependencies;
    inherit buildBunPackage;
    inherit buildSqliteExtensions;
    inherit systemdServiceRef;
  };
in
  lib
