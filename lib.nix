{ ... }:
let
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  allSystems = f: builtins.foldl' ((f: attrs: system: let
    ret = f system;
  in
    builtins.foldl' (attrs: key: attrs // {
      ${key} = (attrs.${key} or { }) // {
        ${system} = ret.${key};
      };
    }) attrs (builtins.attrNames ret)
  ) f) { } systems;

  buildBunDependencies = (pkgs: {
    pname,
    version,
    src,
    hash ? pkgs.lib.fakeSha256,
    flags ? [],
  }: pkgs.stdenv.mkDerivation {
    inherit version src;

    pname = "${pname}_node-modules";
    nativeBuildInputs = [ pkgs.bun ];

    buildPhase = ''
      bun install --no-progress --frozen-lockfile --ignore-scripts ${builtins.concatStringsSep " " flags}
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
  }: pkgs.stdenv.mkDerivation {
      inherit pname version src;
      nativeBuildInputs = [ pkgs.bun dependencies pkgs.makeBinaryWrapper ];

      installPhase = ''
        mkdir -p $out/
        ln -s ${dependencies}/node_modules $out/
        cp -R ./src package.jso[n] tsconfig.jso[n] $out
        makeBinaryWrapper ${pkgs.bun}/bin/bun $out/bun --chdir $out
        makeBinaryWrapper ${pkgs.bun}/bin/bunx $out/bunx --chdir $out
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

  buildAstroWebsite = (pkgs: dependencies: {
    pname,
    version,
    src,
  }: pkgs.stdenv.mkDerivation {
    inherit pname version src;
    buildInputs = [ pkgs.bun dependencies ];

    ASTRO_TELEMETRY_DISABLED = "true";

    configurePhase = ''
      ln -s ${dependencies}/node_modules .
    '';

    buildPhase = ''
      bun ./node_modules/.bin/astro build
    '';

    installPhase = ''
      mkdir -p $out
      mv dist/* $out
    '';
  });

  buildStaticWebserver = (pkgs: pname: version: src: pkgs.stdenv.mkDerivation {
    inherit pname version src;
    buildInputs = [ pkgs.caddy pkgs.makeWrapper ];

    installPhase = ''
      ROOT=$out/html
      mkdir -p $ROOT
      cp -r . $ROOT

      makeWrapper ${pkgs.caddy}/bin/caddy $out/caddy --add-flags "file-server --root $ROOT"
    '';
  });

  mkStaticWebserverShell = (pkgs: src: let
    serve = pkgs.writeShellScriptBin "serve" ''
      ${pkgs.caddy}/bin/caddy file-server --root ${src}
    '';
  in pkgs.mkShell {
    buildInputs = [
      pkgs.caddy
      serve
    ];
  });

  mkStaticWebserverFlake = (pkgs: pname: version: src: {
    devShells.default = mkStaticWebserverShell pkgs src;
    packages.default = buildStaticWebserver pkgs pname version src;
  });

  systemdServiceRef = name: "${name}.service";

  lib = {
    inherit allSystems;
    inherit buildBunDependencies;
    inherit buildBunPackage;
    inherit buildSqliteExtensions;
    inherit buildAstroWebsite;
    inherit buildStaticWebserver;
    inherit mkStaticWebserverShell;
    inherit mkStaticWebserverFlake;
    inherit systemdServiceRef;
  };
in
  lib
