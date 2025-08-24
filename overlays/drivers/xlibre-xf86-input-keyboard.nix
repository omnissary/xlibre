{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-keyboard = final: prev: {
      xorg = prev.xorg // {
        xf86inputkeyboard =
          let
            sources = import inputs.fetchurl-sources;
            basename = "xf86-input-keyboard";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86inputkeyboard-overrideAttrs = prev.xorg.xf86inputkeyboard.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version =
                  if USE-XLIBRE-VERSION-DRIVER then
                    sources.xlibre.xf86-input-keyboard.version
                  else
                    sources.legacy.xf86-input-keyboard.version;
                # Reason to bring back Linux support in xf86-input-mouse and xf86-input-keyboard
                # https://github.com/X11Libre/ports-gentoo/pull/10
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl sources.xlibre.xf86-input-keyboard
                  else
                    prev.fetchurl sources.legacy.xf86-input-keyboard;
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
                  # Both version require this patch to bring back linux support
                  ++
                    lib.optionals
                      (
                        finalAttrs.src.name == "xlibre-xf86-input-keyboard-2.1.0.1.tar.gz"
                        || finalAttrs.src.name == "xf86-input-keyboard-2.1.0.tar.gz"
                      )
                      [
                        # Fix Error message
                        # > configure: error: This is not the mouse driver you are looking for. Use evdev or libinput.
                        (prev.fetchpatch {
                          # Fix Build error:
                          name = "bring-back-xf86-input-keyboard-linux-support.patch";
                          url = "https://github.com/X11Libre/xf86-input-keyboard/commit/15656d9f84f67602c97d244c8c52bb065d52bed9.patch";
                          hash = "sha256-Ya6GzxVlNRAcLwW/mNF7GLYMnSxeyegMbZhtLlSzajM=";
                        })
                      ];

                configureFlags = prevAttrs.configureFlags or [ ] ++ [
                  "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
                ];

                # Bring back linux support.
                # In nixpkgs it was overrided by "platforms = lib.platforms.freebsd ++ lib.platforms.netbsd ++ lib.platforms.openbsd;" in /pkgs/servers/x11/xorg/overrides.nix
                meta.platform = prevAttrs.meta.platform ++ lib.platforms.linux;
              }
            );
          in
          xf86inputkeyboard-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
