{
  lib,
  self,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-mouse = final: prev: {
      xf86-input-mouse =
        let
          sources = import (self + /fetchurl-sources.nix);
          basename = "xf86-input-mouse";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-input-mouse-overrideAttrs = prev.xf86-input-mouse.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version = sources.xlibre.xf86-input-mouse.version;
              # Reason to bring back Linux support in xf86-input-mouse and xf86-input-keyboard:
              # https://github.com/X11Libre/ports-gentoo/pull/10
              src = prev.fetchurl sources.xlibre.xf86-input-mouse;
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
              configureFlags = prevAttrs.configureFlags or [ ] ++ [
                "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
              ];
            }
          );
        in
        xf86-input-mouse-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
