{
  lib,
  self,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-libinput = final: prev: {
      xf86-input-libinput =
        let
          sources = import (self + /fetchurl-sources.nix);
          basename = "xf86-input-libinput";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-input-libinput-overrideAttrs = prev.xf86-input-libinput.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version = sources.xlibre.xf86-input-libinput.version;
              src = prev.fetchurl sources.xlibre.xf86-input-libinput;
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
        xf86-input-libinput-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
