{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-joystick = final: prev: {
      xorg = prev.xorg // {
        xf86inputjoystick =
          let
            sources = import inputs.fetchurl-sources;
            basename = "xf86-input-joystick";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86inputjoystick-overrideAttrs = prev.xorg.xf86inputjoystick.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl sources.xlibre.xf86-input-joystick
                  else
                    prev.fetchurl sources.legacy.xf86-input-joystick;
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
                # Fix error like:
                # > ./configure: line 20204: syntax error near unexpected token `XINPUT,'
                # > ./configure: line 20204: `XORG_DRIVER_CHECK_EXT(XINPUT, inputproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];
              }
            );
          in
          xf86inputjoystick-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
