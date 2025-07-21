{ BUILD-WITH-GLAMOR }:
{ lib, config, ... }:
{
  flake = {
    overlays.xlibre-xserver = final: prev: {
      xorg = prev.xorg // {
        xorgserver = prev.xorg.xorgserver.overrideAttrs (
          finalAttrs: prevAttrs: {
            pname = "xlibre-xserver";
            version = lib.strings.removeSuffix ".tar.gz" (
              lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
            );
            # use tarball because some packages assume this fetch tarball, e.g. tigervnc
            src = prev.fetchurl {
              url = "https://github.com/X11Libre/xserver/archive/refs/tags/xlibre-xserver-25.0.0.5.tar.gz";
              sha256 = "sha256-DVmZeNK8kR0ZnV8YdVKX7C0hakH5HHRrdKHKr1e169M=";
            };
            nativeBuildInputs =
              with prev;
              prevAttrs.nativeBuildInputs or [ ]
              ++ [
                meson
                ninja
              ];
            mesonFlags =
              prevAttrs.mesonFlags or [ ]
              # # configureFlags in /pkgs/servers/x11/xorg/overrides.nix for Linux
              # configureFlags =
              #   [
              #     "--enable-kdrive" # not built by default
              #     "--enable-xephyr"
              #     "--enable-xcsecurity" # enable SECURITY extension
              #     "--with-default-font-path="
              #     # there were only paths containing "${prefix}",
              #     # and there are no fonts in this package anyway
              #     "--with-xkb-bin-directory=${xorg.xkbcomp}/bin"
              #     "--with-xkb-path=${xorg.xkeyboardconfig}/share/X11/xkb"
              #     "--with-xkb-output=$out/share/X11/xkb/compiled"
              #     "--with-log-dir=/var/log"
              #     "--enable-glamor"
              #     "--with-os-name=Nix" # r13y, embeds the build machine's kernel version otherwise
              #   ]
              #   ++ lib.optionals stdenv.hostPlatform.isMusl [
              #     "--disable-tls"
              #   ];
              #
              ++ lib.optionals (!prev.stdenv.hostPlatform.isDarwin) [
                # "--enable-kdrive" # not built by default
                # (lib.mesonBool "kdrive" true) # This is not available in meson
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
                # (lib.mesonOption "os_name" "Nix") # This is not available in meson
              ]
              # This may break xf86-video-ati (Radeon driver)
              # https://github.com/X11Libre/xserver/issues/347
              #
              # Wiki about Graphics devices and drivers support:
              # https://github.com/X11Libre/xserver/wiki/Graphics-devices-&-drivers
              #
              # https://github.com/NixOS/nixpkgs/blob/140a6b4522f396cabf7d91b1ea2a11f063d02126/nixos/modules/services/x11/xserver.nix#L18-L33
              ++ lib.optionals BUILD-WITH-GLAMOR [
                # "--enable-glamor"
                (lib.mesonBool "glamor" true)
              ];
            # remove patches for non-Darwin in /pkgs/servers/x11/xorg/overrides.nix in nixpkgs that failed to apply on xlibre
            patches = lib.optionals (!prev.stdenv.hostPlatform.isDarwin) [ ];
          }
        );
      };
    };
  };
}
