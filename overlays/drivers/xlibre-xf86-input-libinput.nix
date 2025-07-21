{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-input-libinput = final: prev: {
      xorg = prev.xorg // {
        xf86inputlibinput =
          let
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
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-input-libinput/archive/refs/tags/xlibre-xf86-input-libinput-1.5.0.1.tar.gz";
                      sha256 = "08xlw7jk03a5b2xih948baqqhs5k45fnk64h6aw4n593fsqgiw91";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-input-libinput/archive/refs/tags/xf86-input-libinput-1.5.0.tar.gz";
                      sha256 = "sha256-zLTtQLRMm5kdXeon+L71iq000Vv1kIR7SP79WYLH1Fw=";
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
              }
            );
          in
          xf86inputlibinput-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
