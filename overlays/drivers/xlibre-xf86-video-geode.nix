{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-geode = final: prev: {
      xorg = prev.xorg // {
        xf86videogeode =
          let
            basename = "xf86-video-geode";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videogeode-overrideAttrs = prev.xorg.xf86videogeode.overrideAttrs (
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
                      url = "https://github.com/X11Libre/xf86-video-geode/archive/refs/tags/xlibre-xf86-video-geode-2.18.1.1.tar.gz";
                      sha256 = "sha256-+ggm2jJYYiPIbd3s6Uaohsl2fRhrfcEVARxafnSVor4=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-geode/archive/refs/tags/xf86-video-geode-2.18.1.tar.gz";
                      sha256 = "sha256-xCXKbHXb4KH90zfoF+XgSzCAYUs2HFdMBObCpOk3NIc=";
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
          xf86videogeode-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
