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

      f1 = (
        name: value:
          lib.nameValuePair (name) (pkgs.${value})
      );
      # f2 = (name: value: lib.nameValuePair (value) (inputs'.nixpkgs.legacyPackages.xorg.${value}));
      packages-unfiltered = {
        default = pkgs.xorg-server; # overlayed as xlibre-xserver
      }
      // lib.mapAttrs' f1 packages-reference
      # This is actually unnecessary. This only pull normal drivers from nixpkgs without overlay
      # "xf86inputelographics" does not exist in nixpkgs
      # // lib.mapAttrs' f2 (lib.filterAttrs (name: value: value != "xf86inputelographics") packages-reference)
      #
      ;
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
        # Filter and only add to perSystem packages according to system ( when meta.unsupported = false;)
        lib.filterAttrs (
          name: value: lib.isDerivation value && !value.meta.unsupported
        ) packages-unfiltered;

      checks =
        # Filter and only add to perSystem packages according to system ( when meta.unsupported = false;)
        lib.filterAttrs (
          name: value: lib.isDerivation value && !value.meta.unsupported
        ) packages-unfiltered;

      # ABOVE EQUIVALENT TO:
      /*
        {
          # expose this package to inject into xlibre drivers by overrides (the arguments passed to a function)
          xlibre-xserver = pkgs.xorgserver;
          xorg-server = inputs'.nixpkgs.legacyPackages.xorg-server;

          # for debugging
          xlibre-xf86-input-libinput = pkgs.xf86-input-libinput;
          xf86-input-libinput = inputs'.nixpkgs.legacyPackages.xf86-input-libinput;

          xlibre-xf86-input-wacom = pkgs.xf86_input_wacom;
          xf86_input_wacom = inputs'.nixpkgs.legacyPackages.xf86_input_wacom;

          xlibre-xf86-input-mouse = pkgs.xf86inputmouse;
          xf86-input-mouse = inputs'.nixpkgs.legacyPackages.xf86-input-mouse;

          ...
          ...
        };
      */
    };
}
