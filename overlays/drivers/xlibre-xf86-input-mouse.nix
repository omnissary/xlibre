{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-input-mouse = final: prev: {
      xorg = prev.xorg // {
        xf86inputmouse =
          let
            basename = "xf86-input-mouse";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86inputmouse-overrideAttrs = prev.xorg.xf86inputmouse.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                # Reason to bring back Linux support in xf86-input-mouse and xf86-input-keyboard:
                # https://github.com/X11Libre/ports-gentoo/pull/10
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-input-mouse/archive/refs/tags/xlibre-xf86-input-mouse-1.9.5.1.tar.gz";
                      sha256 = "sha256-930WP09cy1rNXMindEgvBQXQ2ECKTg2P8p8WXN5IvA4=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-input-mouse/archive/refs/tags/xf86-input-mouse-1.9.5.tar.gz";
                      sha256 = "sha256-wdoX+pM/ErfU1dQDvaCzt8GR3FsjbmWU68vRJltrdKg=";
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
                patches =
                  prevAttrs.patches or [ ]
                  # Only this xlibre version require this patch to bring back linux support
                  ++ lib.optionals (finalAttrs.src.name == "xlibre-xf86-input-mouse-1.9.5.1.tar.gz") [
                    # Fix Error message
                    # > configure: error: This is not the mouse driver you are looking for. Use evdev or libinput.
                    (prev.fetchpatch {
                      # Fix Build error:
                      name = "bring-back-xf86-input-mouse-linux-support.patch";
                      url = "https://github.com/X11Libre/xf86-input-mouse/commit/ba4c235867569b0bbd214b033c2f61471c1367e9.patch";
                      hash = "sha256-oVpGkjCrhXNx2xMJu05h9ddBpFzrrL/f6SnYrhRP7ak=";
                    })
                  ];
              }
            );
          in
          xf86inputmouse-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
