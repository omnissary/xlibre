# 🏳️‍⚧️ XLibre-overlay: Transformation of the (already Trans) Xorg server in NixOS 💪
![logo](https://codeberg.org/takagemacoed/Screenshots/raw/branch/main/7dcfb685-cb14-4e2f-ba22-4870a131f2e2.jpg "Screenshots")

# Welcome
This is a [experimental](https://nix.dev/manual/nix/2.30/command-ref/new-cli/nix3-flake.html) work-in-progress [flake](https://wiki.nixos.org/wiki/Flake) to [overlay](https://wiki.nixos.org/wiki/Overlay) the package `xorg.xorgserver` with `xlibre-xserver`. It also inculde some X11 drivers overlay.

Things might change at any time and breaking changes may happen.

The code is not good I know. Feel free to help me improve this flake!

# Prerequisites
Flake is an experimental feature and it is required to be enabled.

To enable flake permanently, you'll need to put something like this in your `configuration.nix`:

```nix
{
  # https://nix.dev/manual/nix/2.30/development/experimental-features
  # https://nix.dev/manual/nix/2.30/command-ref/conf-file#conf-experimental-features
  # https://wiki.nixos.org/wiki/Flake#Setup
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
```

Then the NixOS system needs to be [defined as a flake](https://wiki.nixos.org/wiki/NixOS_system_configuration#Defining_NixOS_as_a_flake) in order to consume this flake.

# Status
### x86_64-linux
`xlibre-xserver`, `xlibre-xf86-input-evdev` and `xlibre-xf86-input-libinput`: tested and works.

Other drivers overlay can be successfully build but untested.

### aarch64-linux
`xlibre-xserver`, `xlibre-xf86-input-evdev` and `xlibre-xf86-input-libinput`: successfully build but untested.

Other drivers overlay can be successfully build except some old or incompatible ones: `xlibre-xf86-video-intel`, `xlibre-xf86-video-vmware`, `xlibre-xf86-input-vmmouse`, `xlibre-xf86-video-ast`, `xlibre-xf86-video-vesa`, `xlibre-xf86-video-geode`, `xlibre-xf86-video-siliconmotion`

All the available drivers overlay are listed in [./xlibre-drivers-overlay-choice.nix](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/xlibre-build-options/xlibre-drivers-overlay-choice.nix).

# Common usage
Example of `flake.nix` configuration:

```nix
{
  # ...
  inputs = {
    # ...
    xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay";
    # Optional:
    # inputs.nixpkgs.follows = "nixpkgs";
    # ...
  };

  # usual flake output for NixOS here...
  outputs =
    inputs@{ nixpkgs, ... }:
    {
      nixosConfigurations."yourhostname" = nixpkgs.lib.nixosSystem {
        # ...
        modules = [
          ./configuration.nix

          # Here is the location to consume this flake
          #
          # overlay `xorg.xorgserver` to `xlibre-xserver`
          inputs.xlibre-overlay.nixosModules.overlay-xlibre-xserver

          # Don't add this lines if you want to use drivers provided from nixpkgs
          inputs.xlibre-overlay.nixosModules.overlay-all-xlibre-drivers
          # Instead of `overlay-all-xlibre-drivers`, user can also choose the dirvers invidivually for overlay
          # All available drivers are listed in `xlibre-drivers-overlay-choice.nix`, just prepend them with "overlay-"
          # Examples:
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-input-evdev
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-input-libinput
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-video-amdgpu
          # ...

          # Trying to solve the problem of Nvidia proprietary drivers (set `Option "IgnoreABI" "true"` in Xorg config)
          # This was also mentioned in X11Libre/xserver repo README.md
          inputs.xlibre-overlay.nixosModules.nvidia-ignore-ABI
        ];
        # ...
      };
      #...
    };
}
```

It triggers building all the packages depending on `xorg.xorgserver` after you run `nixos-rebuild`.

# Flake structure
As described above, this flake expose some `nixosModules` for user to apply overlays easily into their own NixOS flake configuration.

You can put them in `imports = [ ];` section of `configuration.nix` or in `modules = [ ];` section in `nixosSystem { }` in `flake.nix`:

`xlibre-xserver` and drivers `nixosModules` are exposed in [./nixosModules/apply-xlibre-xserver-and-drivers.nix](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/nixosModules/apply-xlibre-xserver-and-drivers.nix)

Instead of using `overlay-all-xlibre-drivers`, user can also choose the drivers individually for overlay.

All the available drivers overlay are listed in [./xlibre-drivers-overlay-choice.nix](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/xlibre-build-options/xlibre-drivers-overlay-choice.nix), just prepend "overlay-" of the desired drivers attribute name.

Implementation of all the overlays are located in [./overlays](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/overlays) directory

`nixosModules` `nvidia-ignore-ABI` also exposed for those who use Nvidia proprietary drivers and encounter display problem.

This is implemented in [./nixosModules/nvidia-ignore-ABI.nix](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/nixosModules/nvidia-ignore-ABI.nix)

# This part is optional

## Replace the sources URL of xserver or drivers for further testing
All the sources of xserver and drivers are now located in [./xlibre-build-options/fetchurl-sources.nix](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/0fc6867cc5b8842f07069ca8ef7fab4bbf0aefa6/xlibre-build-options/fetchurl-sources.nix)

This file is now become a flake input "fetchurl-sources". Consumer can override the file by some inputs like:

`inputs.xlibre-overlay.inputs.fetchurl-sources.follow = "your-own-flake-input-about-fetchurl-sources"`

Example of configuration is in the below section.

## Choose between two predefined drivers versions
All the drivers overlays are defined in [./overlays/drivers](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/overlays/drivers).

Most of the drivers there have two predefined version of overlay to choose from. I just do it for fun.

One is from the latest tag on github (default), the other one is the latest tag right before the first xlibre tag was created (supposedly from xorg era) also from github.

It is optionl to choose between two predefined versions.

If it is untouched, it choose the latest tag on github by default (update manually by hand for now).

Extensive instructions of how to choose predefined version is located inside the comments section of `inputs` of `flake.nix`.

The idea is to use user define nix expression to replace the expression in flake.

In this case, to replace the [`xlibre-drivers-overlay-choice` input in this flake](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/826164bebe541d3d62408f4faa741621152e03e7/flake.nix#L18) with [`xlibre-overlay.inputs.xlibre-drivers-overlay-choice.follows` in user's flake](https://codeberg.org/takagemacoed/machine-nixos/src/commit/24fdb0df24909d732464adba980bb3578e7d7d95/flake.nix#L8)

Example of NixOS `flake.nix` configuration for predefined drivers:
```nix
{
  inputs = {
    # ...
    xlibre-overlay = {
      url = "git+https://codeberg.org/takagemacoed/xlibre-overlay";
      # Step 1. Make the inputs "xlibre-drivers-overlay-choice" inside this flake to follow the users defined input
      inputs.xlibre-drivers-overlay-choice.follows = "my-xlibre-my-choice";
    };
    # Step 2. User make a copy of ./xlibre-drivers-overlay-choice.nix file in this repo to their own repo.
    # Step 3. User add an inputs, in this example "my-xlibre-my-choice" on their own flake, and import their own copy of xlibre-drivers-overlay-choice.nix as shown below
    my-xlibre-my-choice = {
      # Point the url of this input to your copy of `xlibre-drivers-overlay-choice.nix`
      # Edit your own xlibre-drivers-overlay-choice.nix copy to choose your desire drivers revision.
      # The true / false will pass into the "USE-XLIBRE-VERSION-DRIVER" variable in the drivers overlays in the `/overlays/drivers` directiory.
      url = "path:./xlibre-drivers-overlay-choice.nix"; # This imply the copy is located in the root of your flake repo
      flake = false;
    };
    # ...
  };

  # outputs = { ...
    # ...
  };
}
```

(Since writing flakes is new to me, this is the only way I can think of to modify the things in the flake by users. I bet it must be other better way like options.)

## Glamor
Glamor is enabled by default. It can be disabled just with the method above ("Choose between two predefined drivers versions" section), but in this case to replace [`xlibre-xserver-build-options` input in this flake](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/826164bebe541d3d62408f4faa741621152e03e7/flake.nix#L22) with [`xlibre-overlay.inputs.xlibre-xserver-build-options.follows` in user's flake](https://codeberg.org/takagemacoed/machine-nixos/src/commit/24fdb0df24909d732464adba980bb3578e7d7d95/flake.nix#L9):

You can also find the example in:

https://codeberg.org/takagemacoed/machine-nixos/src/branch/main/flake.nix

https://codeberg.org/takagemacoed/machine-nixos/src/branch/main/xlibre-build-options/driver-choice.nix

https://codeberg.org/takagemacoed/machine-nixos/src/branch/main/xlibre-build-options/my-xlibre-xserver-build-options.nix

# Known issues
It breaks some packages that were deeply integrated with Xorg.

For example `tigervnc`, the way it was packaged included [some hardcoded xorg paths](https://github.com/NixOS/nixpkgs/blob/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec/pkgs/by-name/ti/tigervnc/package.nix#L69-L92). It assumed the source of `xorg.xorgserver` is a tarball, so `fetchFromGitHub` cannot be used. It failed to build against xlibre-xserver without modification.

# TODO
1. Xnamespace `NixosModule` (After figured it out how to configure).

# Note
The overlays mostly use the nixpkgs functionality `overrideAttrs` to modify the original package if the xorg counterpart is available in nixpkgs. Therefore this flake's overlay is not the whole packaging of the packages, just some modification of them (in nixpkgs) to make them become xlibre. If the corresponding packages change/removed in nixpkgs, it would also affect this flakes' overlay.

I do it that way (for now) because xorg in nixpkgs does not always change. Also nixpkgs have a file in `pkgs/servers/x11/xorg/overrides.nix` that take care of multiple architectures or build cases. Overlaying with `overrideAttrs` affect it less and require less code, so it might help building them in other architectures running NixOS. If some big change happens in nixpkgs' xorg, I may also bring those code into this flake and make it a true packages (like `xlibre-xf86-input-elographics`).
