{ self, inputs, ... }:
{
  flake = {
    nixosModules =
      let
        sources = import (self + /fetchurl-sources.nix);

        packages-reference = import (self + /packages-reference.nix);
        inherit (inputs.nixpkgs) lib;
      in
      {
        overlay-all-xlibre-drivers = {
          nixpkgs.overlays = lib.forEach (lib.remove "xlibre-xserver" (lib.attrNames packages-reference)) (
            name: self.overlays."${name}"
          );
        };
        # EQUIVALENT TO
        /*
          overlay-all-xlibre-drivers = {
            nixpkgs.overlays = [
              self.overlays.xlibre-xf86-input-libinput
              self.overlays.xlibre-xf86-input-wacom
              self.overlays.xlibre-xf86-input-mouse
              self.overlays.xlibre-xf86-input-evdev
              self.overlays.xlibre-xf86-video-amdgpu
              ...
              ...
            ];
          };
        */

        overlay-xlibre-xserver =
          { lib, ... }:
          {
            nixpkgs.overlays = [
              self.overlays.xlibre-xserver
            ];
            services.xserver =
              lib.mkIf
                (
                  # This is required starting from xlibre-xserver version 25.1.0
                  # For some display manager like SDDM
                  # Reason:
                  # https://github.com/orgs/X11Libre/discussions/424
                  # xlibre-xserver dropped server generations and it was introduced in:
                  # https://github.com/X11Libre/xserver/commit/f27e12c918d2bfc26068313e715bed3c2d57fecc
                  # which drop the -reset and -noreset flag effectively. (and
                  # ignore the flags when it was used set in later commit)
                  # However SDDM hardcoded "-noreset" flag in its software:
                  # https://github.com/X11Libre/xserver/issues/1462
                  # And NixOS default "services.xserver.terminateOnRest = true;",
                  # which append "-terminate" on X server command
                  # Since the -noreset in SDDM is no more effective in xlibre-xserver,
                  # somehow the "-terminate" flag prevent SDDM to launch properly.
                  # "services.xserver.terminateOnReset = false" make SDDM works again

                  # https://nix.dev/manual/nix/2.32/language/builtins#builtins-compareVersions
                  # pkgs.xorg.xorgserver.version not work, it shows the version from xorg with unknown reason
                  (builtins.compareVersions sources.xlibre.xserver.version "25.1.0") == 0
                  || (builtins.compareVersions sources.xlibre.xserver.version "25.1.0") == 1
                )
                {
                  terminateOnReset = false;
                };
          };
      }
      // lib.mapAttrs' (
        name: value:
        lib.nameValuePair ("overlay-${name}") ({
          nixpkgs.overlays = [
            self.overlays."${name}"
          ];
        })
      ) (removeAttrs packages-reference [ "xlibre-xserver" ]);
    # EQUIVALENT TO
    /*
      }
      //
        # {
        #   overlay-xlibre-xserver = {
        #     nixpkgs.overlays = [
        #       self.overlays.xlibre-xserver
        #     ];
        #   };
          overlay-xlibre-xf86-input-evdev = {
            nixpkgs.overlays = [
              self.overlays.xlibre-xf86-input-evdev
            ];
          };
          overlay-xlibre-xf86-input-keyboard = {
            nixpkgs.overlays = [
              self.overlays.xlibre-xf86-input-keyboard
            ];
          };
          overlay-xlibre-xf86-input-libinput = {
            nixpkgs.overlays = [
              self.overlays.xlibre-xf86-input-libinput
            ];
          };
          overlay-xlibre-xf86-input-mouse = {
            nixpkgs.overlays = [
              self.overlays.xlibre-xf86-input-mouse
            ];
          };
          ...
          ...
          ...
        };
    */
  };
}
