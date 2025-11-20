{ inputs, ... }:
let
  sources = import inputs.fetchurl-sources;
in
{
  flake = {
    nixosModules = {
      nvidia-ignore-ABI =
        {
          lib,
          pkgs,
          config,
          ...
        }:
        {
          services.xserver =
            lib.mkIf
              (
                # https://wiki.nixos.org/wiki/Nvidia
                # To enable them, add "nvidia" to the list of enabled video drivers defined by the services.xserver.videoDrivers option.
                (builtins.elem "nvidia" config.services.xserver.videoDrivers)
                && (pkgs.xorg.xorgserver.pname == "xlibre-xserver")

                # https://github.com/X11Libre/misc/issues/431
                # This is not required starting from xlibre-xserver version 25.0.0.16+
                # https://nix.dev/manual/nix/2.32/language/builtins#builtins-compareVersions
                # pkgs.xorg.xorgserver.version not work, it shows the version from xorg with unknown reason
                && (builtins.compareVersions sources.xlibre.xserver.version "25.0.0.16") == -1
              )
              {
                serverFlagsSection = ''
                  Option "IgnoreABI" "1"
                '';
              };
        };
    };
  };
}
