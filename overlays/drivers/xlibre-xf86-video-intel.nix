{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-intel = final: prev: {
      xorg = prev.xorg // {
        xf86videointel =
          let
            basename = "xf86-video-intel";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videointel-overrideAttrs = prev.xorg.xf86videointel.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                # older revision from xorg failed to build against xlibre-xserver.
                src = prev.fetchurl {
                  url = "https://github.com/X11Libre/xf86-video-intel/archive/refs/tags/xlibre-xf86-video-intel-3.0.0.1.tar.gz";
                  sha256 = "sha256-hJeBZaw/Tj8G5AeI5iTBPOIViO2sSra1NFoaXHaHhfQ=";
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
          xf86videointel-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
