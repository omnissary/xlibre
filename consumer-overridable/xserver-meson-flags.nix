{ lib, prev }:
[
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
]
