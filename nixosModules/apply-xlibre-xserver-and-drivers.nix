{ self, inputs, ... }:
{
  flake = {
    nixosModules =
      let
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
      }
      // lib.mapAttrs' (
        name: value:
        lib.nameValuePair ("overlay-${name}") ({
          nixpkgs.overlays = [
            self.overlays."${name}"
          ];
        })
      ) packages-reference;
    # EQUIVALENT TO
    /*
      }
      //
        {
          overlay-xlibre-xserver = {
            nixpkgs.overlays = [
              self.overlays.xlibre-xserver
            ];
          };
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
