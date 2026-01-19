{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-video-qxl = final: prev: {
      xorg = prev.xorg // {
        xf86videoqxl =
          let
            sources = import inputs.fetchurl-sources;
            basename = "xf86-video-qxl";
            xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
            xf86videoqxl-overrideAttrs = prev.xorg.xf86videoqxl.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = sources.xlibre.xf86-video-qxl.version;
                # Only xlibre tag is available.
                src = prev.fetchurl sources.xlibre.xf86-video-qxl;
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

                # also need autoreconfHook in buildInputs.
                # Fix error:
                # > ./configure: line 20722: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20722: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];

                configureFlags = prevAttrs.configureFlags or [ ] ++ [
                  "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
                ];

                # This is marked as broken for Aarch64 in nixpkgs commit "9b32dd8933e943f82e48a68cea2ecdc975a9b549", without explaining in the commit message,
                # but it is still on archlinuxarm.org
                # https://archlinuxarm.org/packages/aarch64/xf86-video-qxl
                meta = prevAttrs.meta // {
                  broken = false;
                };

              }
            );
          in
          xf86videoqxl-overrideAttrs.override { inherit xorg-server; };
      };
    };
  };
}
