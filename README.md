# XLibre-overlay
![logo](https://codeberg.org/takagemacoed/Screenshots/raw/branch/main/7dcfb685-cb14-4e2f-ba22-4870a131f2e2.jpg "Screenshots")

# Recent nixpkgs breakage temporary workaround
### TLDR;
1. For users using stable NixOS (nixos-25.11), please use `main` branch of this repo, like this:
```
inputs.xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay";
```
2. For users using unstable NixOS (nixos-unstable, or 26.05), please use `dev-for-26.05` branch of this repo, like this:
```
inputs.xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay?ref=dev-for-26.05";
```
3. Don't let nixpkgs input of this repo follows your own nixpkgs inputs. It may cause breakage.
4. I am personally using `nixos-25.11` on my NixOS and I have no machine for testing `dev-for-26.05`. Please open an issue if you encounter any problems of even better open a PR. Thansk!

### Details:
On Jan 10, `nixos-unstable` branch of nixpkgs broke this repo. After some investigation, I found that the breakage was caused by nixpkgs maintainers gradually renaming some drivers' dependency from `xorgserver` to `xorg-server` [like this](https://github.com/NixOS/nixpkgs/blob/a9d226ccb705b0815620a97f4effaab257a1c1b9/pkgs/by-name/xf/xf86-input-mouse/package.nix#L9). Also, maintainers in nixpkgs have decided to [phase out the xorg namespace](https://github.com/NixOS/nixpkgs/issues/479553), which should entirely break the structure of this repo in the forseeable future.

After recent update of this repo, I found that I can no longer use the most update `nixos-unstable` of nixpkgs because I am using `nixos-25.11` my NixOS. So I splitted it into two different branches:
1. For `main` branch (For 25.11), I pinned nixpkgs of this repo to the [latest working commit (d4815e6a6f767d60edfd2d3ee816d0e9c120fb27)](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/60c80ee17332e3b2c54847eed8d87f3977ad77e0/flake.nix#L18) which have not rename `xorgserver`.
2. For `dev-for-26.05` branch (For unstable, i.e. 26.05), I will try keep updating the nixpkgs periodically and fix build errors. However I have no NixOS running `nixos-unstable` to test this repo. If something breaks on your end please raise an issue or ever better open a PR. Thanks!


# Welcome
This is a third-party [experimental](https://nix.dev/manual/nix/2.30/command-ref/new-cli/nix3-flake.html) work-in-progress [flake](https://wiki.nixos.org/wiki/Flake) to [overlay](https://wiki.nixos.org/wiki/Overlay) the package `xorg.xorgserver` with `xlibre-xserver`. It also inculde some X11 drivers overlay.

`xlibre-xserver` and all the drivers in this flake are provided by [XLibre](https://github.com/X11Libre).

Things might change at any time and breaking changes may happen.

The code is not good I know. Feel free to help me improve this flake!

### Note of xlibre-xserver 25.1.0

When updating to xlibre-xserver 25.1.0, for some display manager, like SDDM, it failed to start in NixOS. It is caused by the `services.xserver.terminateOnReset` default to `true` in NixOS (which introduced the `-terminate` flag for X server). Now, no intervention is required by regular users, because it has already been set in the overlay [HERE (with explanation)](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/ed2406cddad6c2a294d0b98286b6259b2328c202/nixosModules/apply-xlibre-xserver-and-drivers.nix#L32-L65). However if you want to run another display manager like lightdm and want that `-terminate` flag back for some reason, you can set `services.xserver.terminateOnReset = lib.mkForce true` in your NixOS config, but it will not work for SDDM.

### Maintenance

This project now is basically in maintenance mode: i.e. running the `update-sources.sh` script to get the latest release of xlibre-xserver or drivers when it is available and running `build-test.sh` and fix drivers that cannot be build.

If I cannot catch up with the latest release, you can also do it yourself by forking the project.

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

All the available drivers overlay are listed in `./consumer-overridable/drivers-overlay-choice.nix`.

# Common usage
Example of `flake.nix` configuration:

```nix
{
  # ...
  inputs = {
    # ...
    xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay";
    # Optional: # Not prefered because this may break this repo after 2026 Jan 10, because nixpkgs maintainers is changing xorg related code of nixpkgs
    # xlibre-overlay.inputs.nixpkgs.follows = "nixpkgs";
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
          # All available drivers are listed in `./consumer-overridable/drivers-overlay-choice.nix`, just prepend them with "overlay-"
          # Examples:
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-input-evdev
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-input-libinput
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-video-amdgpu
          # ...

          # Trying to solve the problem of Nvidia proprietary drivers (set `Option "IgnoreABI" "true"` in Xorg config)
          # This was also mentioned in X11Libre/xserver repo README.md
          # Starting from xlibre-xserver version 25.0.0.16, this is no longer required and have no effect if enabled
          # inputs.xlibre-overlay.nixosModules.nvidia-ignore-ABI
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

`xlibre-xserver` and drivers `nixosModules` are exposed in `./nixosModules/apply-xlibre-xserver-and-drivers.nix`

Instead of using `overlay-all-xlibre-drivers`, user can also choose the drivers individually for overlay.

All the available drivers overlay are listed in `./consumer-overridable/drivers-overlay-choice.nix`, just prepend "overlay-" of the desired drivers attribute name.

Implementation of all the overlays are located in `./overlays` directory

`nixosModules` `nvidia-ignore-ABI` also exposed for those who use Nvidia proprietary drivers and encounter display problem.

This is implemented in `./nixosModules/nvidia-ignore-ABI.nix`.

# This part is optional

## Replace the sources URL of xserver or drivers as well as xserver meson flags for further testing
All the sources of xserver and drivers are now located in `./consumer-overridable/fetchurl-sources.nix`.

All the xserver meson build flags are now located in `./consumer-overridable/xserver-meson-flags.nix`.

This two files are now become flake inputs `fetchurl-sources` and `xserver-meson-flags` respectivelay . Consumer can override the file by some inputs like:

`inputs.xlibre-overlay.inputs.fetchurl-sources.follow = "your-own-flake-input-about-fetchurl-sources"`

`inputs.xlibre-overlay.inputs.xserver-meson-flags.follow = "your-own-flake-input-about-xserver-meson-flags"`

Example of configuration is in the section below.

## Choose between two predefined drivers versions (xlibre and legacy)
All the sources of xserver and drivers are now located in `./consumer-overridable/fetchurl-sources.nix`.

Most of the drivers there have two predefined version of overlay to choose from. I just do it for fun.

One is from the latest tag on github (default, xlibre), the other one is the latest tag right before the first xlibre tag was created (supposedly from xorg era) also from github. (legacy).

It is optionl to choose between two predefined versions (xlibre and legacy).

If it is untouched, it choose the latest tag on github by default (xlibre).

Extensive instructions of how to choose predefined version is located inside the comments section of `inputs` of `flake.nix`.

The idea is to use user define nix expression to replace the expression in flake.

In this case, to replace the `xlibre-drivers-overlay-choice` input in this flake with `xlibre-overlay.inputs.xlibre-drivers-overlay-choice.follows` in user's flake.

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
    # Step 2. User make a copy of ./consumer-overridable/drivers-overlay-choice.nix file in this repo to their own repo.
    # Step 3. User add an inputs, in this example "my-xlibre-my-choice" on their own flake, and import their own copy of drivers-overlay-choice.nix as shown below
    my-xlibre-my-choice = {
      # Point the url of this input to your copy of `drivers-overlay-choice.nix`
      # Edit your own drivers-overlay-choice.nix copy to choose your desire drivers revision.
      # The true / false will pass into the "USE-XLIBRE-VERSION-DRIVER" variable in the drivers overlays in the `/overlays/drivers` directiory.
      url = "path:./drivers-overlay-choice.nix"; # This imply the copy is located in the root of your flake repo
      flake = false;
    };
    # ...
  };

  # outputs = { ...
    # ...
  };
}
```

# Known issues
It breaks some packages that were deeply integrated with Xorg.

1. For example `tigervnc`, the way it was packaged included [some hardcoded xorg paths](https://github.com/NixOS/nixpkgs/blob/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec/pkgs/by-name/ti/tigervnc/package.nix#L69-L92). It assumed the source of `xorg.xorgserver` is a tarball, so `fetchFromGitHub` cannot be used. It failed to build against xlibre-xserver without modification.

2. Anything pull `xpra` as dependences (e.g. `x11docker`) will also be failed to build when `xlibre-xf86-video-dummy` is used. Further information and the workaround can be found [here](https://codeberg.org/takagemacoed/xlibre-overlay/issues/2).

# TODO
1. Xnamespace `NixosModule` (After figured it out how to configure).

# Note
The overlays mostly use the nixpkgs functionality `overrideAttrs` to modify the original package if the xorg counterpart is available in nixpkgs. Therefore this flake's overlay is not the whole packaging of the packages, just some modification of them (in nixpkgs) to make them become xlibre. If the corresponding packages change/removed in nixpkgs, it would also affect this flakes' overlay.

I do it that way (for now) because xorg in nixpkgs does not always change. Also nixpkgs have a file in `pkgs/servers/x11/xorg/overrides.nix` that take care of multiple architectures or build cases. Overlaying with `overrideAttrs` affect it less and require less code, so it might help building them in other architectures running NixOS. If some big change happens in nixpkgs' xorg, I may also bring those code into this flake and make it a true packages (like `xlibre-xf86-input-elographics`).
