{ ... }: {
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
}