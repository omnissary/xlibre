{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-video-intel = final: prev: {
      xf86-video-intel =
        let
          sources = import inputs.fetchurl-sources;
          basename = "xf86-video-intel";
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86-video-intel-overrideAttrs = prev.xf86-video-intel.overrideAttrs (
            finalAttrs: prevAttrs: {
              pname = "${basename}";
              version = sources.xlibre.xf86-video-intel.version;
              # This override the name set in /pkgs/servers/x11/xorg/overrides.nix in nikpkgs
              name = "${finalAttrs.pname}-${finalAttrs.version}";

              # older revision from xorg failed to build against xlibre-xserver.
              src = prev.fetchurl sources.xlibre.xf86-video-intel;

              # nativeBuildInputs =
              #   with prev;
              #   prevAttrs.nativeBuildInputs or [ ]
              #   # referece to /pkgs/by-name/xf/xf86_input_wacom/package.nix in nixpkgs
              #   ++ [
              #     autoreconfHook
              #     # pkg-config #already in /pkgs/servers/x11/xorg/default.nix in nixpkgs
              #
              #     # solve error message
              #     # configure.ac:41: error: must install xorg-macros 1.8 or later before running autoconf/autogen
              #     # util-macros # provides xorg-macros
              #     util-macros
              #
              #     xorg-server
              #   ];

              # In nixpkgs from commit "875c3ada5d65a27d6aeace6fdaf08f4f3667a2a2", it started to build with meson and ninja, which failed to build in this setup
              nativeBuildInputs = with prev; [
                # meson
                # ninja
                pkg-config

                autoreconfHook
                util-macros
                xorg-server
              ];

              patches =
                prevAttrs.patches or [ ]
                ++
                  lib.optionals
                    (
                      # https://nix.dev/manual/nix/2.18/language/builtins#builtins-compareVersions
                      # xorgserver.version not work, it shows the version from xorg with unknown reason
                      (builtins.compareVersions sources.xlibre.xserver.version "25.0.0.7") == 1
                      && (finalAttrs.version == "3.0.0.1")
                    )
                    [
                      # https://github.com/ONykyf/X11Libre-SlackBuild/blob/b079336ed7ee915d68213092d2cfcdf346b76469/patch/xlibre-video-intel/xf86-video-intel-maxclients.patch
                      (self + /overlays/patches/xlibre-xf86-video-intel/maxclients.patch)
                    ];

              configureFlags = prevAttrs.configureFlags or [ ] ++ [
                # "--with-xorg-conf-dir=${placeholder "out"}/share/X11/xorg.conf.d"
                "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
              ];

            }
          );
        in
        xf86-video-intel-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
