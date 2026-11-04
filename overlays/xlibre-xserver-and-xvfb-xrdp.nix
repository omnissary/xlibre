{ lib, self, ... }:
{
  flake =
    let
      sources = import (self + /fetchurl-sources.nix);
    in
    {
      overlays.xlibre-xserver = final: prev: {
        xorg-server = prev.xorg-server.overrideAttrs (
          finalAttrs: prevAttrs: {
            pname = "xlibre-xserver";
            version = sources.xlibre.xserver.version;
            # use tarball because some packages assume this fetch tarball, e.g. tigervnc
            src = prev.fetchurl sources.xlibre.xserver;

            mesonFlags =
              prevAttrs.mesonFlags or [ ]
              ++ lib.optionals prev.stdenv.hostPlatform.isLinux [
                # configureFlags in /pkgs/servers/x11/xorg/overrides.nix for non-Darwin
                # https://github.com/NixOS/nixpkgs/blob/140a6b4522f396cabf7d91b1ea2a11f063d02126/pkgs/servers/x11/xorg/overrides.nix#L1035-L1052

                # "--enable-kdrive" # not built by default
                # (lib.mesonBool "kdrive" true) # This is not available in meson_option
                # "--enable-xephyr"
                (lib.mesonBool "xephyr" true)
                # "--enable-xcsecurity" # enable SECURITY extension
                (lib.mesonBool "xcsecurity" true)
                # "--with-default-font-path="
                (lib.mesonOption "default_font_path" "")
                # "--with-xkb-bin-directory=${xorg.xkbcomp}/bin"
                (lib.mesonOption "xkb_bin_dir" "${prev.xkbcomp}/bin")
                # "--with-xkb-output=$out/share/X11/xkb/compiled"
                (lib.mesonOption "xkb_output_dir" "$out/share/X11/xkb/compiled")
                # "--with-xkb-path=${xorg.xkeyboardconfig}/share/X11/xkb"
                (lib.mesonOption "xkb_dir" "${prev.xkeyboard-config}/share/X11/xkb")
                # "--with-log-dir=/var/log"
                (lib.mesonOption "localstatedir" "/var")
                # "--with-os-name=Nix" # r13y, embeds the build machine's kernel version otherwise
                # (lib.mesonOption "os_name" "Nix") # This is not available in meson_option

                # "--enable-glamor"
                (lib.mesonBool "glamor" true)

                # Fix rootless support
                (lib.mesonBool "systemd_logind" true)

                # Other mesonFlags
                (lib.mesonBool "udev" true)
                (lib.mesonBool "udev_kms" true)
                (lib.mesonBool "libunwind" true)
              ];

            patches =
              prevAttrs.patches or [ ]
              ++
                lib.optionals
                  (
                    # Fix drivers failed to build against xlibre-xserver 25.1.6 issue
                    # https://github.com/X11Libre/xserver/pull/2918
                    # https://github.com/X11Libre/xserver/issues/2892
                    #
                    # https://nix.dev/manual/nix/2.18/language/builtins#builtins-compareVersions
                    # xorgserver.version not work, it shows the version from xorg with unknown reason
                    (builtins.compareVersions sources.xlibre.xserver.version "25.1.6") == 0
                  )
                  [
                    (prev.fetchpatch {
                      name = "Adds-#mesondefine-for-conf-variable-added-in-a86be24.patch";
                      url = "https://github.com/X11Libre/xserver/commit/a7f884f66e186632deb0365c7f869b341767d739.patch";
                      hash = "sha256-MOwAPIMhBABUMWNvX3tgCFlLXH3YPE7Pp+0WcxqDjtY=";
                    })
                  ];

          }
        );
        # X virtual framebuffer
        # xvfb is basically xorg-server but with different build flags.
        # It is separated into different package since nixos-26.05
        # xvfb = prev.xvfb.overrideAttrs (
        #   finalAttrs: prevAttrs: {
        #     version = sources.xlibre.xserver.version;
        #     src = prev.fetchurl sources.xlibre.xserver;
        #     # In nixos-26.05, this is still build with Makefile, but it is not possible for xlibre-xserver
        #     nativeBuildInputs =
        #       with prev;
        #       prevAttrs.nativeBuildInputs or [ ]
        #       ++ [
        #         meson
        #         ninja
        #       ];
        #     mesonFlags = [
        #       (lib.mesonBool "xvfb" true)
        #       (lib.mesonBool "xorg" false)
        #       (lib.mesonBool "xquartz" false)
        #       (lib.mesonOption "xkb_bin_dir" "${prev.xkbcomp}/bin")
        #       (lib.mesonOption "xkb_dir" "${prev.xkeyboard-config}/share/X11/xkb")
        #       (lib.mesonOption "xkb_output_dir" "$out/share/X11/xkb/compiled")
        #     ];
        #   }
        # );
        #
        # If xvfb use xlibre code, it trigger massive packages rebuilds expecially python packages and some of them might failed to build
        # To avoid it, xvfb just use xorg-server source from nixpkgs.
        xvfb = prev.xvfb.override { xorg-server = prev.xorg-server; };

        # https://codeberg.org/takagemacoed/xlibre-overlay/issues/13
        # fix xrdp not building by using xorg-server
        xrdp = prev.xrdp.override { xorg-server = prev.xorg-server; };
      };
    };
}
