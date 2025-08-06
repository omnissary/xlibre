{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-input-void = final: prev: {
      xorg = prev.xorg // {
        xf86inputvoid =
          let
            sources = import ./sources.nix;
            basename = "xf86-input-void";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86inputvoid-overrideAttrs = prev.xorg.xf86inputvoid.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl sources.xlibre.xf86-input-void
                  else
                    prev.fetchurl sources.legacy.xf86-input-void;
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
                # # also need autoreconfHook in buildInputs.
                # # Fix error like:
                # # > ./configure: line 20409: syntax error near unexpected token `RANDR,'
                # # > ./configure: line 20409: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                # buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];
                #
              }
            );
          in
          xf86inputvoid-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
