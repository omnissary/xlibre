{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-synaptics = final: prev: {
      xf86-input-synaptics =
        let
          sources = import inputs.fetchurl-sources;
          basename = "xf86-input-synaptics";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-input-synaptics-overrideAttrs = prev.xf86-input-synaptics.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version =
                if USE-XLIBRE-VERSION-DRIVER then
                  sources.xlibre.xf86-input-synaptics.version
                else
                  sources.legacy.xf86-input-synaptics.version;
              src =
                if USE-XLIBRE-VERSION-DRIVER then
                  prev.fetchurl sources.xlibre.xf86-input-synaptics
                else
                  prev.fetchurl sources.legacy.xf86-input-synaptics;
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
              # Fix error:
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
        xf86-input-synaptics-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
