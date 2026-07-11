{
  description = "XLibre-overlay: Transformation of the (already trans) Xorg server in NixOS!!!";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Bisect result:
    # a9d226ccb705b0815620a97f4effaab257a1c1b9 is the first bad commit
    # commit a9d226ccb705b0815620a97f4effaab257a1c1b9 (HEAD)
    # Author: quantenzitrone <general@dev.quantenzitrone.eu>
    # Date:   Sat Dec 13 05:16:15 2025 +0100
    #
    #     xf86-input-mouse: refactor, move to pkgs/by-name & rename from xorg.xf86inputmouse
    #
    #     relevant changes:
    #     - switch to GitLab source instead of release tarball
    #
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # flake.lock commit: c5296fdd05cfa2c187990dd909864da9658df755
    # nixpkgs.url = "github:NixOS/nixpkgs/d4815e6a6f767d60edfd2d3ee816d0e9c120fb27"; # latest working commit without changing xorgserver to xorg-server
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

        packages-reference = import ./packages-reference.nix;

        # Combination of the use of "lib.nameValuePair", and "lib.mapAttrs'"
        # https://github.com/NixOS/nixpkgs/blob/3ff0e34b1383648053bba8ed03f201d3466f90c9/lib/attrsets.nix#L1030-L1045
        flakeModules = lib.mapAttrs' (
          name: value: lib.nameValuePair "overlay-${name}" (importApply ./overlays/drivers/${name}.nix)
        ) (lib.filterAttrs (name: value: name != "xlibre-xserver") packages-reference)
        # EQUIVALENT TO:
        /*
          flakeModules = {
            overlay-xlibre-xf86-input-libinput = importApply ./overlays/drivers/xlibre-xf86-input-libinput.nix;
            overlay-xlibre-xf86-input-wacom = importApply ./overlays/drivers/xlibre-xf86-input-wacom.nix;
            ......
            ......
          }
        */
        ;
      in
      {
        imports =
          # Part 1.
          # The most important package in packages-and-checks.nix is xlibre-xserver.
          # Others just for build test. This expose the overlayed
          # xlibre-xserver package (defined in ./overlays/xlibre-xserver.nix (Part 2 below)).
          # It is injected into the rest of xlibre drivers overlay (by nixpkgs'
          # "override"), for them to build against xlibre-server in this flake.
          [ ./packages-and-checks.nix ]
          # Part 2.
          # These files just define how the packages should be overlayed.
          ++ [
            ./overlays/xlibre-xserver-and-xvfb-xrdp.nix
          ]
          # Part 3
          # overlay drivers, all build against xlibre-xserver with above
          # overlay injected in it
          #
          # https://flake.parts/dogfood-a-reusable-module.html
          # Import the defined dogfoods in the let...in section above, and later
          # consume them in "flake" section (Part. 6) in this flake.nix
          ++ lib.forEach (lib.attrNames (
            lib.filterAttrs (name: value: name != "xlibre-xserver") packages-reference
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
        systems = [
          # only x86_64-linux is tested.
          "x86_64-linux"
          "aarch64-linux"
        ];
      }
    );
}
