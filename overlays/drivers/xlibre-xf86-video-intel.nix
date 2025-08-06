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
      xorg = prev.xorg // {
        xf86videointel =
          let
            sources = import inputs.fetchurl-sources;
            basename = "xf86-video-intel";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videointel-overrideAttrs = prev.xorg.xf86videointel.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                # older revision from xorg failed to build against xlibre-xserver.
                src = prev.fetchurl sources.xlibre.xf86-video-intel;
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
                  let
                    # xorgserver.version not work, it shows the version from xorg with unknown reason
                    xlibre-xserver-version = lib.strings.removeSuffix ".tar.gz" (
                      lib.strings.removePrefix "${xorgserver.pname}-" xorgserver.src.name
                    );
                  in
                  prevAttrs.patches or [ ]
                  # Both version require this patch to bring back linux support
                  ++
                    lib.optionals
                      (
                        # https://nix.dev/manual/nix/2.18/language/builtins#builtins-compareVersions
                        # xorgserver.version not work, it shows the version from xorg with unknown reason
                        (builtins.compareVersions "${xlibre-xserver-version}" "25.0.0.7") == 1
                        # I "think" next version of xf86-video-intel may not need this
                        && (finalAttrs.version == "3.0.0.1")
                      )
                      [
                        # https://github.com/ONykyf/X11Libre-SlackBuild/blob/b079336ed7ee915d68213092d2cfcdf346b76469/patch/xlibre-video-intel/xf86-video-intel-maxclients.patch
                        (self + /overlays/patches/xlibre-xf86-video-intel/maxclients.patch)
                      ];

              }
            );
          in
          xf86videointel-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
