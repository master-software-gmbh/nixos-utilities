{ ... }: pkgs: let
  list = pkgs.writeShellScriptBin "actions-list" ''
    echo "actions-list"
    echo "actions-build-package"
    echo "actions-create-release"
  '';
  buildPackage = pkgs.writeShellScriptBin "actions-build-package" ''
    mkdir -p ./.github/workflows
    cp ${./workflows/build-package.yaml} ./.github/workflows/build.yaml
  '';
  createRelease = pkgs.writeShellScriptBin "actions-create-release" ''
    mkdir -p ./.github/workflows
    cp ${./workflows/create-release.yaml} ./.github/workflows/release.yaml
  '';
in [
  list
  buildPackage
  createRelease
]
