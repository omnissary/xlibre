{ lib, inputs, ... }:
{
  flake =
    let
      sources = import inputs.fetchurl-sources;
      xserver-meson-flags = import inputs.xserver-meson-flags;
    in
    {
      overlays.xlibre-xserver = final: prev: {
          xorg-server = prev.xorg-server.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "xlibre-xserver";
              version = sources.xlibre.xserver.version;
              # use tarball because some packages assume this fetch tarball, e.g. tigervnc
              src = prev.fetchurl sources.xlibre.xserver;
              # src = prev.fetchurl {
              #   url = "https://github.com/X11Libre/xserver/archive/refs/tags/xlibre-xserver-25.0.0.8.tar.gz";
              #   sha256 = "sha256-m+R/VfsSWK3cOLJKSDImR8Zejjj3hALhQl+CgucHNIM=";
              # };
              nativeBuildInputs =
                with prev;
                prevAttrs.nativeBuildInputs or [ ]
                ++ [
                  meson
                  ninja
                ];

              mesonFlags =
                prevAttrs.mesonFlags or [ ]
                ++ lib.optionals (!prev.stdenv.hostPlatform.isDarwin) xserver-meson-flags { inherit lib prev; };

              # remove patches for non-Darwin in /pkgs/servers/x11/xorg/overrides.nix in nixpkgs that failed to apply on xlibre
              patches = lib.optionals (!prev.stdenv.hostPlatform.isDarwin) [ ];

              # https://github.com/NixOS/nixpkgs/blob/e9b2b4fb322259098c2d5a1239479fe31382cc2a/pkgs/servers/x11/xorg/overrides.nix#L1056-L1064
              # fix sed command below ( use xlibre-xserver-version instead of xorg-server-version)
              postInstall = ''
                rm -fr $out/share/X11/xkb/compiled # otherwise X will try to write in it
                ( # assert() keeps runtime reference xorgserver-dev in xf86-video-intel and others
                  cd "$dev"
                  for f in include/xorg/*.h; do
                    sed "1i#line 1 \"${finalAttrs.pname}-${finalAttrs.version}/$f\"" -i "$f"
                  done
                )
              '';

            }
          );
      };
    };
}
