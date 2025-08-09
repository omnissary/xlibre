{ BUILD-WITH-GLAMOR }:
{ lib, inputs, ... }:
{
  flake =
    let
      sources = import inputs.fetchurl-sources;
    in
    {
      overlays.xlibre-xserver = final: prev: {
        xorg = prev.xorg // {
          xorgserver = prev.xorg.xorgserver.overrideAttrs (
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
                # configureFlags in /pkgs/servers/x11/xorg/overrides.nix for non-Darwin
                # https://github.com/NixOS/nixpkgs/blob/140a6b4522f396cabf7d91b1ea2a11f063d02126/pkgs/servers/x11/xorg/overrides.nix#L1035-L1052
                ++ lib.optionals (!prev.stdenv.hostPlatform.isDarwin) [
                  # "--enable-kdrive" # not built by default
                  # (lib.mesonBool "kdrive" true) # This is not available in meson_option
                  # "--enable-xephyr"
                  (lib.mesonBool "xephyr" true)
                  # "--enable-xcsecurity" # enable SECURITY extension
                  (lib.mesonBool "xcsecurity" true)
                  # "--with-default-font-path="
                  (lib.mesonOption "default_font_path" "")
                  # "--with-xkb-bin-directory=${xorg.xkbcomp}/bin"
                  (lib.mesonOption "xkb_bin_dir" "${prev.xorg.xkbcomp}/bin")
                  # "--with-xkb-output=$out/share/X11/xkb/compiled"
                  (lib.mesonOption "xkb_output_dir" "$out/share/X11/xkb/compiled")
                  # "--with-xkb-path=${xorg.xkeyboardconfig}/share/X11/xkb"
                  (lib.mesonOption "xkb_dir" "${prev.xorg.xkeyboardconfig}/share/X11/xkb")
                  # "--with-log-dir=/var/log"
                  (lib.mesonOption "localstatedir" "/var")
                  # "--with-os-name=Nix" # r13y, embeds the build machine's kernel version otherwise
                  # (lib.mesonOption "os_name" "Nix") # This is not available in meson_option
                ]
                # https://github.com/NixOS/nixpkgs/blob/140a6b4522f396cabf7d91b1ea2a11f063d02126/nixos/modules/services/x11/xserver.nix#L18-L33
                ++ lib.optionals BUILD-WITH-GLAMOR [
                  # "--enable-glamor"
                  (lib.mesonBool "glamor" true)
                ];
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
    };
}
