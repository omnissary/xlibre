{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-evdev = final: prev: {
      xf86-input-evdev =
        let
          sources = import inputs.fetchurl-sources;
          basename = "xf86-input-evdev";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-input-evdev-overrideAttrs = prev.xf86-input-evdev.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version =
                if USE-XLIBRE-VERSION-DRIVER then
                  sources.xlibre.xf86-input-evdev.version
                else
                  sources.legacy.xf86-input-evdev.version;
              src =
                if USE-XLIBRE-VERSION-DRIVER then
                  prev.fetchurl sources.xlibre.xf86-input-evdev
                else
                  prev.fetchurl sources.legacy.xf86-input-evdev;
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
              configureFlags = prevAttrs.configureFlags or [ ] ++ [
                "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
              ];

            }
          );
        in
        xf86-input-evdev-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
