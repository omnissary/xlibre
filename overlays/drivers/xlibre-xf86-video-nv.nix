{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-nv = final: prev: {
      xorg = prev.xorg // {
        xf86videonv =
          let
            basename = "xf86-video-nv";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videonv-overrideAttrs = prev.xorg.xf86videonv.overrideAttrs (
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
                      url = "https://github.com/X11Libre/xf86-video-nv/archive/refs/tags/xlibre-xf86-video-nv-2.1.23.1.tar.gz";
                      sha256 = "sha256-VbhHhCo37EuqUqehd1mAaAGs2Z9B1s3tM6owdX8nZCE=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-nv/archive/refs/tags/xf86-video-nv-2.1.23.tar.gz";
                      sha256 = "sha256-bAa48eeOCRkHLqD5PSkRRWXpG0qpCS69UeyMyouDniE=";
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
                # > ./configure: line 20260: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20260: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];
              }
            );
          in
          xf86videonv-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
