{ ... }: pkgs: let
  list = pkgs.writeShellScriptBin "actions-list" ''
    echo "actions-list"
    echo "actions-build-package"
  '';
  buildPackage = pkgs.writeShellScriptBin "actions-build-package" ''
    mkdir -p ./.github/workflows
    cp ${./workflows/build-package.yaml} ./.github/workflows/build.yaml
  '';
in [
  list
  buildPackage
]
