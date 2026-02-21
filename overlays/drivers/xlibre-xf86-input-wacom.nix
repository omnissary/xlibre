{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-wacom = final: prev: {
      xf86-input-wacom =
        let
          sources = import inputs.fetchurl-sources;
          basename = "xf86-input-wacom";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-input-wacom-overrideAttrs = prev.xf86-input-wacom.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "xlibre-${basename}";
              version =
                if USE-XLIBRE-VERSION-DRIVER then
                  sources.xlibre.xf86-input-wacom.version
                else
                  sources.legacy.xf86-input-wacom.version;

              src =
                if USE-XLIBRE-VERSION-DRIVER then
                  prev.fetchurl sources.xlibre.xf86-input-wacom
                else
                  prev.fetchurl sources.legacy.xf86-input-wacom;
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
        xf86-input-wacom-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
