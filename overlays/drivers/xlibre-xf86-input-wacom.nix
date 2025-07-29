{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-input-wacom = final: prev: {
      # xf86_input_wacom located in /pkgs/by-name/xf/xf86_input_wacom, not in "xorg" attribute set
      xf86_input_wacom =
        let
          basename = "xf86-input-wacom";
          xorgserver = self.packages.${prev.system}.xlibre-xserver;
          xf86_input_wacom-overrideAttrs = prev.xf86_input_wacom.overrideAttrs (
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
                    url = "https://github.com/X11Libre/xf86-input-wacom/archive/refs/tags/xlibre-xf86-input-wacom-1.2.3.1.tar.gz";
                    sha256 = "1v87jajjybc3myaxw132fsih0b1raig3kgjrbfl8brbrkqi7n7wn";
                  }
                else
                  prev.fetchurl {
                    url = "https://github.com/X11Libre/xf86-input-wacom/archive/refs/tags/xf86-input-wacom-1.2.3.tar.gz";
                    sha256 = "sha256-hfBsUwQXpT83lJbRAbAFxH1721XSN0zqTE6OzfTdHus=";
                  };
              patches =
                prevAttrs.patches or [ ]
                # Both version require this patch for linux support
                ++
                  lib.optionals
                    (
                      finalAttrs.src.name == "xf86-input-wacom-1.2.3.tar.gz"
                      || finalAttrs.src.name == "xlibre-xf86-input-wacom-1.2.3.1.tar.gz"
                    )
                    [
                      (prev.fetchpatch {
                        # https://github.com/X11Libre/xf86-input-wacom/pull/6
                        # Fix Build error:
                        # > ../src/x11/xf86Wacom.c: In function 'wcmLog':
                        # > ../src/x11/xf86Wacom.c:74:9: error: implicit declaration of function 'xf86VIDrvMsgVerb'; did you mean 'xf86IDrvMsgVerb'? [-Wimplicit-function-declaration]
                        # >    74 |         xf86VIDrvMsgVerb(priv->frontend, xtype, 0, format, args);
                        # >       |         ^~~~~~~~~~~~~~~~
                        # >       |         xf86IDrvMsgVerb
                        name = "xf86IDrvMsgVerb-fix.patch";
                        url = "https://github.com/X11Libre/xf86-input-wacom/commit/bb65266d0ce671a9f3d7623125855c4da43ecbae.patch";
                        hash = "sha256-qUlRQ4u7PWvOeBIqHuxN9nNdJYMj4njtFzgNS1u9HHY=";
                      })
                    ];
            }
          );
        in
        xf86_input_wacom-overrideAttrs.override { inherit xorgserver; };
    };
  };
}
