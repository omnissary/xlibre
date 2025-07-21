{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-r128 = final: prev: {
      xorg = prev.xorg // {
        xf86videor128 =
          let
            basename = "xf86-video-r128";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videor128-overrideAttrs = prev.xorg.xf86videor128.overrideAttrs (
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
                      url = "https://github.com/X11Libre/xf86-video-r128/archive/refs/tags/xlibre-xf86-video-r128-6.13.0.1.tar.gz";
                      sha256 = "sha256-CK3rYh92iBpcxAggb01EEgw4R+6JZHoWriRnRBXXAwE=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-r128/archive/refs/tags/xf86-video-r128-6.13.0.tar.gz";
                      sha256 = "sha256-aoyM8O8BUybpf2B3woKXMa6+lXc2VoVtJOAKr3/9ZIQ=";
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
                # Fix error like this:
                # > ./configure: line 20301: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20301: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];

                meta = prevAttrs.meta // {
                  broken = false; # this is marked as broken in /pkgs/servers/x11/xorg/overrides.nix in nixpkgs
                };

              }
            );
          in
          xf86videor128-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
