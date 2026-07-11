{
  lib,
  self,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-video-siliconmotion = final: prev: {
      xf86-video-siliconmotion =
        let
          sources = import (self + /fetchurl-sources.nix);
          basename = "xf86-video-siliconmotion";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-video-siliconmotion-overrideAttrs = prev.xf86-video-siliconmotion.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version = sources.xlibre.xf86-video-siliconmotion.version;
              # older revision from xorg failed to build against xlibre-xserver.
              src = prev.fetchurl sources.xlibre.xf86-video-siliconmotion;
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
              # Fix error like this:
              # > ./configure: line 20301: syntax error near unexpected token `RANDR,'
              # > ./configure: line 20301: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
              # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
              buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];

              patches =
                prevAttrs.patches or [ ]
                # only xorg version require this patch
                ++ lib.optionals (finalAttrs.src.name == "xf86-video-siliconmotion-1.7.10.tar.gz") [
                  (prev.fetchpatch {
                    # Fix Build error:
                    # > smi_video.c:524:9: error: implicit declaration of function 'Xasprintf'; did you mean 'asprintf'? [-Wimplicit-function-declaration]
                    # >   524 |     if (Xasprintf(&name_string, "%s-%s-%s",
                    # >       |         ^~~~~~~~~
                    # >       |         asprintf
                    name = "use-asprintf()-instead-of-Xasprintf().patch";
                    url = "https://github.com/X11Libre/xf86-video-siliconmotion/commit/ad54a83d36c8766cdd8218592ce0265e4c88a24d.patch";
                    hash = "sha256-EKdsEFLaBA1wSq7eoPd7mooF+EpRgkBChXRs7SpGZ7g=";
                  })
                ];

              configureFlags = prevAttrs.configureFlags or [ ] ++ [
                "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
              ];

            }
          );
        in
        xf86-video-siliconmotion-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
