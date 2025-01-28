{ ... }: let
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];
in {
  allSystems = f: builtins.foldl' ((f: attrs: system: let
    ret = f system;
  in
    builtins.foldl' (attrs: key: attrs // {
      ${key} = (attrs.${key} or { }) // {
        ${system} = ret.${key};
      };
    }) attrs (builtins.attrNames ret)
  ) f) { } systems;
}
