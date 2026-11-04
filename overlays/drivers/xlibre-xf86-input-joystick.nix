{
  lib,
  self,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-joystick = final: prev: {
      xf86-input-joystick =
        let
          sources = import (self + /fetchurl-sources.nix);
          basename = "xf86-input-joystick";
          xorg-server = final.xorg-server;
          xf86-input-joystick-overrideAttrs = prev.xf86-input-joystick.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version = sources.xlibre.xf86-input-joystick.version;
              src = prev.fetchurl sources.xlibre.xf86-input-joystick;
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
                  util-macros

                ];
              # also need autoreconfHook in buildInputs.
              # Fix error like:
              # > ./configure: line 20204: syntax error near unexpected token `XINPUT,'
              # > ./configure: line 20204: `XORG_DRIVER_CHECK_EXT(XINPUT, inputproto)'
              # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
              buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];

              configureFlags = prevAttrs.configureFlags or [ ] ++ [
                "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
              ];

            }
          );
        in
        xf86-input-joystick-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
