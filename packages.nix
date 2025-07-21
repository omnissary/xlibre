{ inputs, self, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      inputs',
      self',
      lib,
      ...
    }:
    let
      packages-reference = import (self + /packages-reference.nix);
    in
    {
      # https://flake.parts/overlays.html#consuming-an-overlay
      # Consuming overlays
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = lib.forEach (lib.attrNames packages-reference) (name: self.overlays."${name}");
        # EQUIVALENT TO
        /*
          overlays = [
            # xlibre-xserver
            self.overlays.xlibre-xserver
            # drivers
            self.overlays.xlibre-xf86-input-libinput
            self.overlays.xlibre-xf86-input-wacom
            self.overlays.xlibre-xf86-input-mouse
            self.overlays.xlibre-xf86-input-evdev
            ...
            ...
          ];
        */
      };

      packages =
        let
          inherit (inputs.nixpkgs) lib;
          f1 = (
            name: value:
            if name != "xlibre-xf86-input-wacom" then # this pkgs not in xorg
              lib.nameValuePair (name) (pkgs.xorg.${value})
            else
              lib.nameValuePair (name) (pkgs.${value})
          );
          # f2 = (name: value: lib.nameValuePair (value) (inputs'.nixpkgs.legacyPackages.xorg.${value}));
        in
        {
          default = self'.packages.xlibre-xserver;
        }
        // lib.mapAttrs' f1 packages-reference
      # This is actually unnecessary. This only pull normal drivers from nixpkgs without overlay
      # "xf86inputelographics" does not exist in nixpkgs
      # // lib.mapAttrs' f2 (lib.filterAttrs (name: value: value != "xf86inputelographics") packages-reference)
      #
      ;

      # ABOVE EQUIVALENT TO:
      /*
        {
          # expose this package to inject into xlibre drivers by overrides (the arguments passed to a function)
          xlibre-xserver = pkgs.xorg.xorgserver;
          xorgserver = inputs'.nixpkgs.legacyPackages.xorg.xorgserver;

          # for debugging
          xlibre-xf86-input-libinput = pkgs.xorg.xf86inputlibinput;
          xf86inputlibinput = inputs'.nixpkgs.legacyPackages.xorg.xf86inputlibinput;

          xlibre-xf86-input-wacom = pkgs.xf86_input_wacom;
          xf86_input_wacom = inputs'.nixpkgs.legacyPackages.xf86_input_wacom;

          xlibre-xf86-input-mouse = pkgs.xorg.xf86inputmouse;
          xf86inputmouse = inputs'.nixpkgs.legacyPackages.xorg.xf86inputmouse;

          ...
          ...
        };
      */
    };
}
