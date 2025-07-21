{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-dummy = final: prev: {
      xorg = prev.xorg // {
        xf86videodummy =
          let
            basename = "xf86-video-dummy";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videodummy-overrideAttrs = prev.xorg.xf86videodummy.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version = lib.strings.removeSuffix ".tar.gz" (
                  lib.strings.removePrefix "${basename}-" (
                    lib.strings.removePrefix "${finalAttrs.pname}-" finalAttrs.src.name
                  )
                );
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-dummy/archive/refs/tags/xlibre-xf86-video-dummy-0.4.1.1.tar.gz";
                      sha256 = "sha256-vk1PUhM+2oG4xUgqEnx0iJS1ES7XCH1lY8SygenVBM0=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-dummy/archive/refs/tags/xf86-video-dummy-0.4.1.tar.gz";
                      sha256 = "sha256-P1ydmQSw5Wg+3VRtfeKWAEXbybXjAdq9OrujwvH3G+o=";
                    };
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
                # > ./configure: line 20280: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20280: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];
              }
            );
          in
          xf86videodummy-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
