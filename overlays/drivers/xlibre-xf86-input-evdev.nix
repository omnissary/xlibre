{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-input-evdev = final: prev: {
      xorg = prev.xorg // {
        xf86inputevdev =
          let
            basename = "xf86-input-evdev";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86inputevdev-overrideAttrs = prev.xorg.xf86inputevdev.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-input-evdev/archive/refs/tags/xlibre-xf86-input-evdev-2.11.0.1.tar.gz";
                      sha256 = "sha256-lgwTwgLcsCncFYBt2c/5inc8vFqmwgocmlPjXtbXS+8=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-input-evdev/archive/refs/tags/xf86-input-evdev-2.11.0.tar.gz";
                      sha256 = "sha256-u8PyA/5WDtKxjlPZTMRsKaGY/Sw+ME8lmAzaC+7exRw=";
                    };
                nativeBuildInputs =
                  with prev;
                  prevAttrs.nativeBuildInputs or [ ]
                  # referece to /pkgs/by-name/xf/xf86_input_wacom/package.nix in nixpkgs
                  ++ [
                    autoreconfHook
                    # pkg-config #already in /pkgs/servers/x11/xorg/default.nix in nixpkgs

                    # solve error message
                    # configure.ac:41: error: must install xorg-macros 1.8 or later before running autoconf/autogen
                    # util-macros # provides xorg-macros
                    xorg.utilmacros
                  ];
              }
            );
          in
          xf86inputevdev-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
