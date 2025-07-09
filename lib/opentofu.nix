{ ... }: pkgs: { path ? "." }: let
  provision = pkgs.writeShellScriptBin "provision" ''
    ${pkgs.opentofu}/bin/tofu -chdir=${path} init && ${pkgs.opentofu}/bin/tofu -chdir=${path} apply -auto-approve
  '';
in {
  inputs = [ pkgs.opentofu provision ];
  provision = {
    type = "app";
    program = "${provision}/bin/provision";
  };
}