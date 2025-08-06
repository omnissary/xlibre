{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-libinput = final: prev: {
      xorg = prev.xorg // {
        xf86inputlibinput =
          let
            sources = import inputs.fetchurl-sources;
            basename = "xf86-input-libinput";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86inputlibinput-overrideAttrs = prev.xorg.xf86inputlibinput.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl sources.xlibre.xf86-input-libinput
                  else
                    prev.fetchurl sources.legacy.xf86-input-libinput;
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
              }
            );
          in
          xf86inputlibinput-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
