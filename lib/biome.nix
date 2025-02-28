{ ... }: pkgs: let
  localConfig = {
    "$schema" = "https://biomejs.dev/schemas/1.8.2/schema.json";
    extends = [./biome.json];
  };
  update = pkgs.writeShellScriptBin "biome-update" ''
    if [ -f biome.json ]; then
      jq '.extends = ["${./biome.json}"]' biome.json > tmp.json
      mv tmp.json biome.json
    else
      echo '${builtins.toJSON localConfig}' > biome.json
    fi
  '';
  check = pkgs.writeShellScriptBin "biome-check" ''
    ${update}/bin/biome-update
    ${pkgs.bun}/bin/bun pm ls -g 2>&1 | grep @biomejs/biome > /dev/null || ${pkgs.bun}/bin/bun add -g @biomejs/biome > /dev/null
    ${pkgs.bun}/bin/bunx @biomejs/biome check --write ./
  '';
in [
  update
  check
]
