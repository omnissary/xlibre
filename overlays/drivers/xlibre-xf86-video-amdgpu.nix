{ USE-XLIBRE-VERSION-DRIVER }:
{
  lib,
  self,
  inputs,
  ...
}:
{
  flake = {
    overlays.xlibre-xf86-video-amdgpu = final: prev: {
      xorg = prev.xorg // {
        xf86videoamdgpu =
          let
            sources = import inputs.fetchurl-sources;
            basename = "xf86-video-amdgpu";
            xorgserver = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
            xf86videoamdgpu-overrideAttrs = prev.xorg.xf86videoamdgpu.overrideAttrs (
              finalAttrs: prevAttrs: {
                pname = "xlibre-${basename}";
                version =
                  if USE-XLIBRE-VERSION-DRIVER then
                    sources.xlibre.xf86-video-amdgpu.version
                  else
                    sources.legacy.xf86-video-amdgpu.version;
                src =
                  if USE-XLIBRE-VERSION-DRIVER then
                    prev.fetchurl sources.xlibre.xf86-video-amdgpu
                  else
                    prev.fetchurl sources.legacy.xf86-video-amdgpu;
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

                configureFlags = prevAttrs.configureFlags or [ ] ++ [
                  "--with-xorg-conf-dir=${placeholder "out"}/share/X11/xorg.conf.d"
                  "--with-xorg-module-dir=${placeholder "out"}/lib/xorg/modules"
                  # "--prefix=/usr"
                  "--enable-glamor"
                ];
              }
            );
          in
          xf86videoamdgpu-overrideAttrs.override { inherit xorgserver; };
      };
    };
  };
}
