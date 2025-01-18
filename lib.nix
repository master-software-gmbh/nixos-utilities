{ pkgs, ... }:
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
        makeBinaryWrapper ${pkgs.bun}/bin/bun $out/bun --chdir $out
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

  buildStaticWebserver = (pkgs: manifest: src: pkgs.stdenv.mkDerivation {
    inherit src;

    name = manifest.name;
    version = manifest.version;
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

  mkStaticWebserverFlake = (pkgs: manifest: src: {
    devShells.default = mkStaticWebserverShell pkgs src;
    packages.default = buildStaticWebserver pkgs manifest src;
  });

  systemdServiceRef = name: "${name}.service";

  lib = {
    inherit allSystems;
    inherit buildBunDependencies;
    inherit buildBunPackage;
    inherit buildSqliteExtensions;
    inherit buildStaticWebserver;
    inherit mkStaticWebserverShell;
    inherit mkStaticWebserverFlake;
    inherit systemdServiceRef;
  };
in
  lib
