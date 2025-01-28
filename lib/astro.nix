{ ... }: {
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
      mv dist $out
    '';
  });
}
