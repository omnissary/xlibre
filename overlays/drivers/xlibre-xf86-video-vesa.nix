{
  lib,
  self,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-video-vesa = final: prev: {
      xf86-video-vesa =
        let
          sources = import (self + /fetchurl-sources.nix);
          basename = "xf86-video-vesa";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-video-vesa-overrideAttrs = prev.xf86-video-vesa.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version = sources.xlibre.xf86-video-vesa.version;
              src = prev.fetchurl sources.xlibre.xf86-video-vesa;
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
              # > ./configure: line 20292: syntax error near unexpected token `RANDR,'
              # > ./configure: line 20292: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
              # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
              buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];

              configureFlags = prevAttrs.configureFlags or [ ] ++ [
                "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
              ];

              # This is marked as broken for Aarch64 in nixpkgs commit "afd4dcf86fcc1e26c65df17645432277b12a2078" with explanation in commit message,
              # but it is still on other platforms like archlinuxarm.org and freshports.org and alpinelinux, etc
              # https://archlinuxarm.org/packages/aarch64/xf86-video-vesa
              # https://www.freshports.org/x11-drivers/xf86-video-vesa/
              # https://packages.gentoo.org/packages/x11-drivers/xf86-video-vesa
              # https://pkgs.alpinelinux.org/package/edge/community/aarch64/xf86-video-vesa
              meta = prevAttrs.meta // {
                broken = false;
              };

            }
          );
        in
        xf86-video-vesa-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
