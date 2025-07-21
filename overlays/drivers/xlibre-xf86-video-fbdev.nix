{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-fbdev = final: prev: {
      xorg = prev.xorg // {
        xf86videofbdev =
          let
            basename = "xf86-video-fbdev";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videofbdev-overrideAttrs = prev.xorg.xf86videofbdev.overrideAttrs (
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
                      url = "https://github.com/X11Libre/xf86-video-fbdev/archive/refs/tags/xlibre-xf86-video-fbdev-0.5.1.1.tar.gz";
                      sha256 = "sha256-U6xJ+fqJJxnqFKSLATqNagbZa9XNgARtmewNzYnau18=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-fbdev/archive/refs/tags/xf86-video-fbdev-0.5.1.tar.gz";
                      sha256 = "sha256-aZ+TjHq//OFna481IM8BI08qX8Kzr37l0I5JgKgES0s=";
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
                # > ./configure: line 20301: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20301: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];
              }
            );
          in
          xf86videofbdev-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
