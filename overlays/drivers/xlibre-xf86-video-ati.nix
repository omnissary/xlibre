{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-ati = final: prev: {
      xorg = prev.xorg // {
        xf86videoati =
          let
            basename = "xf86-video-ati";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videoati-overrideAttrs = prev.xorg.xf86videoati.overrideAttrs (
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
                      url = "https://github.com/X11Libre/xf86-video-ati/archive/refs/tags/xfree-xf86-video-ati-22.0.0.1.tar.gz";
                      sha256 = "sha256-5nIzXmw9qqeGmuWXJBl6euK0PIBeZSg5XwRzAoYvZUE=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-ati/archive/refs/tags/xf86-video-ati-22.0.0.tar.gz";
                      sha256 = "sha256-Ot26i+eR0JKdecATg3SPUg7EgdgNfKtnBXQak3Z22YY=";
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

                # also need autoreconfHook in buildInputs.
                # Fix error:
                # > ./configure: line 20559: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20559: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];
              }
            );
          in
          xf86videoati-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
