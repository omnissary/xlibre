{
  description = "XLibre-overlay: Transformation of the (already trans) Xorg server in NixOS!!!";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems = {
      url = "path:./systems.nix";
      flake = false;
    };

    # https://github.com/nix-systems/nix-systems
    # This make it possible for user to choose predefined drivers revision
    # This is totally optional. You can omit this part to get the latest drivers from xlibre
    # Step 1. User make a copy of ./xlibre-drivers-overlay-choice.nix file in this flake to their own flake repo.
    # Step 2. User add an inputs, say "my-xlibre-my-choice" on their own flake, and import their own copy of xlibre-drivers-overlay-choice.nix just like below in this flake.
    # Step 3. Add 'inputs.xlibre-overlay.inputs.xlibre-drivers-overlay-choice.follow = "my-xlibre-my-choice"' in users flake.
    # Step 4. Edit your own xlibre-drivers-overlay-choice.nix to choose your desire drivers revision.
    # The true/false will pass into the "USE-XLIBRE-VERSION-DRIVER" variable in the drivers overlays in `./overlays/drivers`.
    # Browse through `./overlays/drivers` for more details of what revision it actually use.
    xlibre-drivers-overlay-choice = {
      url = "path:./xlibre-build-options/xlibre-drivers-overlay-choice.nix";
      flake = false;
    };
    xlibre-xserver-build-options = {
      url = "path:./xlibre-build-options/xlibre-xserver-build-options.nix"; # set building with glamor
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, ... }:
      let
        # https://flake.parts/dogfood-a-reusable-module.html
        # Define the dogfoods
        inherit (flake-parts-lib) importApply;
        inherit (inputs.nixpkgs) lib;

        if-use-xlibre-version-driver = import inputs.xlibre-drivers-overlay-choice;
        xlibre-xserver-build-options = import inputs.xlibre-xserver-build-options;
        packages-reference = import ./packages-reference.nix;

        # Combination of the use of "lib.nameValuePair", and "lib.mapAttrs'"
        # https://github.com/NixOS/nixpkgs/blob/3ff0e34b1383648053bba8ed03f201d3466f90c9/lib/attrsets.nix#L1030-L1045
        flakeModules =
          lib.mapAttrs' (
            name: value:
            lib.nameValuePair ("overlay-${name}") (
              importApply ./overlays/drivers/${name}.nix {
                USE-XLIBRE-VERSION-DRIVER = value; # defined in ./xlibre-drivers-overlay-choice.nix
              }
            )
          ) if-use-xlibre-version-driver
          # EQUIVALENT TO:
          /*
            flakeModules = {
              overlay-xlibre-xf86-input-libinput = importApply ./overlays/drivers/xlibre-xf86-input-libinput.nix {
                USE-XLIBRE-VERSION-DRIVER = true; # defined in ./xlibre-drivers-overlay-choice.nix
              };
              overlay-xlibre-xf86-input-wacom = importApply ./overlays/drivers/xlibre-xf86-input-wacom.nix {
                USE-XLIBRE-VERSION-DRIVER = true; # defined in ./xlibre-drivers-overlay-choice.nix
               };
              ......
              ......
            }
          */
          // {
            overlay-xlibre-xserver = importApply ./overlays/xlibre-xserver.nix xlibre-xserver-build-options;
          };
      in
      {
        imports =
          # Part 1.
          # The most important package in packages.nix is xlibre-xserver.
          # Others just for build test. This expose the overlayed
          # xlibre-xserver package (defined in ./overlays/xlibre-xserver.nix (Part 2 below)).
          # It is injected into the rest of xlibre drivers overlay (by nixpkgs'
          # "override"), for them to build against xlibre-server in this flake.
          [ ./packages.nix ]
          # Part 2.
          # These files just define how the packages should be overlayed.
          # use above importApply method instead to pass build-options (BUILD-WITH-GLAMOR)
          # ++ [ ./overlays/xlibre-xserver.nix ]
          # Part 3
          # overlay drivers, all build against xlibre-xserver with above
          # overlay injected in it
          #
          # https://flake.parts/dogfood-a-reusable-module.html
          # Import the defined dogfoods in the let...in section above, and later
          # consume them in "flake" section (Part. 6) in this flake.nix
          ++ lib.forEach (lib.attrNames (
            # don't exclude "xlibre-xserver" because it also in flakeModules now (to let user configure BUILD-WITH-GLAMOR)
            # lib.filterAttrs (name: value: name != "xlibre-xserver") packages-reference
            packages-reference
          )) (name: flakeModules."overlay-${name}")
          # This is EQUIVALENT TO:
          /*
            [
              flakeModules.overlay-xlibre-xf86-input-libinput
              flakeModules.overlay-xlibre-xf86-input-wacom
              flakeModules.overlay-xlibre-xf86-input-mouse
              flakeModules.overlay-xlibre-xf86-input-evdev
              flakeModules.overlay-xlibre-xf86-input-keyboard
              flakeModules.overlay-xlibre-xf86-video-amdgpu
              ...
              ...
            ]
          */
          ++
            # Part 4.
            # These files expose nixosModules for users to apply the above
            # defined overlays to their NixOS configuration
            [
              # apply overlay of xlibre-server and drivers
              ./nixosModules/apply-xlibre-xserver-and-drivers.nix
            ]
          ++
            # Part 5.
            # https://github.com/X11Libre/xserver#upgrade-notice
            # This file expose nixosModules to set nvidia Ignore ABI if
            # encounter Nvidia problems
            [ ./nixosModules/nvidia-ignore-ABI.nix ]
          ++
            # Misc.
            # formatter used to format the code in this flake
            [ ./formatter.nix ];

        # Part 6.
        # https://flake.parts/dogfood-a-reusable-module.html
        # Actually consume the imported dogfoods
        flake = { inherit flakeModules; };

        # systems for which you want to build the `perSystem` attributes
        # systems = [
        #
        #   # only x86_64-linux is tested.
        #   "x86_64-linux"
        #   "aarch64-linux"
        #   "aarch64-darwin"
        #   "x86_64-darwin"
        # ];
        systems = import inputs.systems;
      }
    );
}
