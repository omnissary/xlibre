{ ... }:
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
