{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-mga = final: prev: {
      xorg = prev.xorg // {
        xf86videomga =
          let
            sources = import ./sources.nix;
            basename = "xf86-video-mga";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videomga-overrideAttrs = prev.xorg.xf86videomga.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl sources.xlibre.xf86-video-mga
                  else
                    prev.fetchurl sources.legacy.xf86-video-mga;
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
                # > ./configure: line 20323: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20323: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];
              }
            );
          in
          xf86videomga-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
