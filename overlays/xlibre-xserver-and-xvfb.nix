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

            mesonFlags =
              prevAttrs.mesonFlags or [ ]
              ++ lib.optionals prev.stdenv.hostPlatform.isLinux xserver-meson-flags { inherit lib prev; };
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
      };
    };
}
