{ ... }: pkgs: let
  init = pkgs.writeShellScriptBin "structurizr-init" ''
    mkdir -p ./docs/adrs ./docs/docs
    cp ${./workspace.dsl} ./docs/workspace.dsl
  '';
  start = pkgs.writeShellScriptBin "structurizr-start" ''
    docker run -it --rm -p 8080:8080 -v ./docs:/usr/local/structurizr structurizr/lite
  '';
in [
  init
  start
]
