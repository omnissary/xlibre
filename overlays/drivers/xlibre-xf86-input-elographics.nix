{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-input-elographics = final: prev: {
      xorg = prev.xorg // {
        xf86inputelographics =
          let
            sources = import inputs.fetchurl-sources;
            basename = "xf86-input-elographics";
            xorgserver = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          in
          # This package does not exist in nixpkgs
          prev.stdenv.mkDerivation (finalAttrs: {
            pname = "xlibre-${basename}";
            version =
              if USE-XLIBRE-VERSION-DRIVER then
                sources.xlibre.xf86-input-elographics.version
              else
                sources.legacy.xf86-input-elographics.version;
            src =
              if USE-XLIBRE-VERSION-DRIVER then
                prev.fetchurl sources.xlibre.xf86-input-elographics
              else
                prev.fetchurl sources.legacy.xf86-input-elographics;
            hardeningDisable = [
              "bindnow"
              "relro"
            ];
            strictDeps = true;
            nativeBuildInputs =
              with prev;
              [ pkg-config ]
              # referece to /pkgs/by-name/xf/xf86_input_wacom/package.nix in nixpkgs
              ++ [
                autoreconfHook

                # solve error message
                # configure.ac:41: error: must install xorg-macros 1.8 or later before running autoconf/autogen
                # util-macros # provides xorg-macros
                xorg.utilmacros

              ];
            buildInputs =
              with prev;
              [
                xorgproto
                libinput
                xorgserver
              ]
              # also need autoreconfHook in buildInputs.
              # Fix error like:
              # > ./configure: line 20204: syntax error near unexpected token `XINPUT,'
              # > ./configure: line 20204: `XORG_DRIVER_CHECK_EXT(XINPUT, inputproto)'
              # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
              ++ [
                autoreconfHook
              ];

            configureFlags = [
              "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
            ];

            passthru.tests.pkg-config = prev.testers.testMetaPkgConfig finalAttrs.finalPackage;
            meta = {
              pkgConfigModules = [ "xorg-elographics" ];
              platforms = lib.platforms.unix;
            };

          });
      };
    };
  };
}
