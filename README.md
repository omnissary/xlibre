# XLibre-overlay
![logo](https://codeberg.org/takagemacoed/Screenshots/raw/branch/main/7dcfb685-cb14-4e2f-ba22-4870a131f2e2.jpg "Screenshots")

### TLDR;
## Update of 2026-07-11
1. For users using stable NixOS (nixos-26.05), please use `main` or `dev-for-26.05` branch of this repo, like this:
```
inputs.xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay";
or
inputs.xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay?ref=dev-for-26.05";
```
2. For users using unstable NixOS (nixos-unstable, or 26.11), please use `dev-26.11` branch of this repo, like this:
```
inputs.xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay?ref=dev-26.11";
```
3. For users still using deprecated nixos-25.11, please use `dev` branch of this repo, like this:
```
inputs.xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay?ref=dev";
```
4. I am personally using `nixos-26.05` on my NixOS and I only have a VM for testing `dev-26.11`. Please open an issue if you encounter any problems of even better open a PR. Thanks!

5. I am cleaning up some old code and old features. If you want that features, please let me know.

6. Example of usage in flake.nix:
```nix
{
  # ...
  inputs = {
    ...
    xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay";
    # Optional:
    # xlibre-overlay.inputs.nixpkgs.follows = "nixpkgs";
    ...
  };

  # usual flake output for NixOS here...
  outputs =
    inputs@{ nixpkgs, ... }:
    {
      nixosConfigurations."yourhostname" = nixpkgs.lib.nixosSystem {
        # ...
        modules = [
          ./configuration.nix
          { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }

          # overlay `xorg.xorgserver` to `xlibre-xserver`
          inputs.xlibre-overlay.nixosModules.overlay-xlibre-xserver

          # Overlay all drivers in this repo
          inputs.xlibre-overlay.nixosModules.overlay-all-xlibre-drivers
          # Instead of `overlay-all-xlibre-drivers` above, user can also choose the drivers invidivually for overlay if something breaks
          # All available drivers are listed in `./packages-reference.nix`, just prepend the key with "overlay-" like below
          # Examples:
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-input-evdev
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-input-libinput
          # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xf86-video-amdgpu
          # ...
        ];
        # ...
      };
      #...
    };
}
```

# Welcome
This is a third-party [experimental](https://nix.dev/manual/nix/2.30/command-ref/new-cli/nix3-flake.html) work-in-progress [flake](https://wiki.nixos.org/wiki/Flake) to [overlay](https://wiki.nixos.org/wiki/Overlay) the package `xorg.xorgserver` with `xlibre-xserver`. It also inculde some X11 drivers overlay.

`xlibre-xserver` and all the drivers in this flake are provided by [XLibre](https://github.com/X11Libre).

Things might change at any time and breaking changes may happen.

### Maintenance

This project now is basically in maintenance mode: i.e. I just periodically runn the `update-sources.sh` script to get the latest release of xlibre-xserver or drivers when it is available and running `build-test.sh` and fix drivers that cannot be build.

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

All the available drivers overlay are listed in `packages-reference.nix`.

# Common usage
Example of `flake.nix` configuration is moved to TL,DR; section:

It triggers building all the packages depending on `xorg.xorgserver` after you run `nixos-rebuild`.

# Flake structure
As described above, this flake expose some `nixosModules` for user to apply overlays easily into their own NixOS flake configuration.

You can put them in `imports = [ ];` section of `configuration.nix` or in `modules = [ ];` section in `nixosSystem { }` in `flake.nix`:

`xlibre-xserver` and drivers `nixosModules` are exposed in `./nixosModules/apply-xlibre-xserver-and-drivers.nix`

Instead of using `overlay-all-xlibre-drivers`, user can also choose the drivers individually for overlay.

All the available drivers overlay are listed in `./packages-reference.nix`, just prepend "overlay-" of the desired drivers attribute name.

Implementation of all the overlays are located in `./overlays` directory

`nixosModules` `nvidia-ignore-ABI` also exposed for those who use Nvidia proprietary drivers and encounter display problem.

This is implemented in `./nixosModules/nvidia-ignore-ABI.nix`.

# This part is optional

## Replace the sources URL of xserver or drivers for further testing
All the sources of xserver and drivers are now located in `./consumer-overridable/fetchurl-sources.nix`.

This file is now become flake inputs `fetchurl-sources` . Consumer can override the file by some inputs like:

`inputs.xlibre-overlay.inputs.fetchurl-sources.follow = "your-own-flake-input-about-fetchurl-sources"`


# Known issues
It breaks some packages that were deeply integrated with Xorg.

1. For example `tigervnc`, the way it was packaged included [some hardcoded xorg paths](https://github.com/NixOS/nixpkgs/blob/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec/pkgs/by-name/ti/tigervnc/package.nix#L69-L92). It assumed the source of `xorg.xorgserver` is a tarball, so `fetchFromGitHub` cannot be used. It failed to build against xlibre-xserver without modification.

2. Anything pull `xpra` as dependences (e.g. `x11docker`) will also be failed to build when `xlibre-xf86-video-dummy` is used. Further information and the workaround can be found [here](https://codeberg.org/takagemacoed/xlibre-overlay/issues/2).

3. `xvfb` and `xrdp` is failed to build against xlibre-xserevre, so now it is just build against xorg-server from nixpkgs. For details see [here](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/83bf43bd48e4b50661be3a929a8c3f09cdcd8aef/overlays/xlibre-xserver-and-xvfb-xrdp.nix#L78-L110).


## nixpkgs breakage temporary workaround on January 2026
### Details:
On Jan 10, `nixos-unstable` branch of nixpkgs broke this repo. After some investigation, I found that the breakage was caused by nixpkgs maintainers gradually renaming some drivers' dependency from `xorgserver` to `xorg-server` [like this](https://github.com/NixOS/nixpkgs/blob/a9d226ccb705b0815620a97f4effaab257a1c1b9/pkgs/by-name/xf/xf86-input-mouse/package.nix#L9). Also, maintainers in nixpkgs have decided to [phase out the xorg namespace](https://github.com/NixOS/nixpkgs/issues/479553), which should entirely break the structure of this repo in the forseeable future.

After recent update of this repo, I found that I can no longer use the most update `nixos-unstable` of nixpkgs because I am using `nixos-25.11` my NixOS. So I splitted it into two different branches:
1. For `main` branch (For 25.11), I pinned nixpkgs of this repo to the [latest working commit (d4815e6a6f767d60edfd2d3ee816d0e9c120fb27)](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/60c80ee17332e3b2c54847eed8d87f3977ad77e0/flake.nix#L18) which have not rename `xorgserver`.
2. For `dev-for-26.05` branch (For unstable, i.e. 26.05), I will try keep updating the nixpkgs periodically and fix build errors. However I have no NixOS running `nixos-unstable` to test this repo. If something breaks on your end please raise an issue or ever better open a PR. Thanks!

### Note of xlibre-xserver 25.1.0

When updating to xlibre-xserver 25.1.0, for some display manager, like SDDM, it failed to start in NixOS. It is caused by the `services.xserver.terminateOnReset` default to `true` in NixOS (which introduced the `-terminate` flag for X server). Now, no intervention is required by regular users, because it has already been set in the overlay [HERE (with explanation)](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/ed2406cddad6c2a294d0b98286b6259b2328c202/nixosModules/apply-xlibre-xserver-and-drivers.nix#L32-L65). However if you want to run another display manager like lightdm and want that `-terminate` flag back for some reason, you can set `services.xserver.terminateOnReset = lib.mkForce true` in your NixOS config, but it will not work for SDDM.
