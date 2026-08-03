{
  self,
  ...
}:
{
  flake = {
    overlays.xpra = final: prev: {
      xpra =
        let
          xorg-server = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xserver;
          xf86videodummy = self.packages.${prev.stdenv.hostPlatform.system}.xlibre-xf86-video-dummy;
          xpra-overrideAttrs = prev.xpra.overrideAttrs (
            finalAttrs: prevAttrs:
            let
              xorgModulePaths = prev.writeText "module-paths" ''
                Section "Files"
                  ModulePath "${xorg-server}/lib/xorg/modules"
                  ModulePath "${xorg-server}/lib/xorg/modules/extensions"
                  ModulePath "${xorg-server}/lib/xorg/modules/drivers"
                  ModulePath "${xf86videodummy}/lib/xorg/modules/drivers"
                EndSection
              '';
            in
            {
              postInstall = ''
                # append module paths to xorg.conf
                cat ${xorgModulePaths} >> $out/etc/xpra/xorg.conf
                cat ${xorgModulePaths} >> $out/etc/xpra/xorg-uinput.conf

                # make application icon visible to desktop environemnts
                icon_dir="$out/share/icons/hicolor/64x64/apps"
                mkdir -p "$icon_dir"
                ln -sr "$out/share/icons/xpra.png" "$icon_dir"
                ln -s ${prev.xpra-html5}/share/xpra/www $out/share/xpra/www;
              '';
            }
          );
        in
        xpra-overrideAttrs.override { inherit xorg-server; };
    };
  };
}
