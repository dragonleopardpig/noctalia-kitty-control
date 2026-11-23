{
  description = "Noctalia community/kitty-control bar and panel plugin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      plugin = pkgs.runCommand "noctalia-plugin-kitty-control" { } ''
        cp -r ${./kitty-control} $out
      '';
    in {
      lib = {
        pluginDir = ./kitty-control;
      };
      packages.${system} = {
        inherit plugin;
        default = plugin;
      };
      checks.${system} = {
        manifest = pkgs.runCommand "noctalia-kitty-control-checked" {
          nativeBuildInputs = [ pkgs.python3 ];
        } ''
          python3 - <<'PY'
          import json
          import tomllib
          from pathlib import Path

          cat = tomllib.loads(Path("${./catalog.toml}").read_text(encoding="utf-8"))
          man = tomllib.loads(Path("${./kitty-control/plugin.toml}").read_text(encoding="utf-8"))
          row = cat["plugin"][0]
          for k in ("id", "name", "version", "plugin_api"):
              assert row[k] == man[k], f"{k} mismatch: {row[k]!r} != {man[k]!r}"
          for rel in ("bar.luau", "panel.luau", "translations/en.json"):
              assert (Path("${./kitty-control}") / rel).is_file(), f"missing {rel}"
          json.loads(Path("${./kitty-control/translations/en.json}").read_text(encoding="utf-8"))
          print("kitty-control manifest check OK")
          PY
          touch $out
        '';
      };
    };
}
