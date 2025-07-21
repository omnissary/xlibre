{ USE-XLIBRE-VERSION-DRIVER }:
{ lib, self, ... }:
{
  flake = {
    overlays.xlibre-xf86-video-amdgpu = final: prev: {
      xorg = prev.xorg // {
        xf86videoamdgpu =
          let
            basename = "xf86-video-amdgpu";
            xorgserver = self.packages.${prev.system}.xlibre-xserver;
            xf86videoamdgpu-overrideAttrs = prev.xorg.xf86videoamdgpu.overrideAttrs (
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
                      url = "https://github.com/X11Libre/xf86-video-amdgpu/archive/refs/tags/xlibre-xf86-video-amdgpu-23.0.0.1.tar.gz";
                      sha256 = "sha256-wj5qUbzdFqRVhRzCQXVUsDLFRdMEZmh6T4wg8/po+Ws=";
                    }
                  else
                    prev.fetchurl {
                      url = "https://github.com/X11Libre/xf86-video-amdgpu/archive/refs/tags/xf86-video-amdgpu-23.0.0.tar.gz";
                      sha256 = "sha256-9ZPadeSfW8b1AGavA5Q7YiyAe5uHkcZUX00cYGb6FfE=";
                    };
                # outputs = [ "out" ];
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
                # > ./configure: line 20532: syntax error near unexpected token `RANDR,'
                # > ./configure: line 20532: `XORG_DRIVER_CHECK_EXT(RANDR, randrproto)'
                # https://wiki.nixos.org/wiki/Packaging/Quirks_and_Caveats#Configure_Scripts_that_are_using_pkg-config
                buildInputs = with prev; prevAttrs.buildInputs or [ ] ++ [ autoreconfHook ];

                # configureFlags = prevAttrs.configureFlags or [ ] ++ [
                # configureFlags = [
                #   "--with-xorg-conf-dir=${placeholder "out"}/share/X11/xorg.conf.d"
                #   "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
                #   # "--prefix=/usr"
                #   # "--enable-glamor"
                # ];
              }
            );
          in
          xf86videoamdgpu-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
