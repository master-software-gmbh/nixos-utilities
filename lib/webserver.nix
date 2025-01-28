{ ... }: {
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
}
