# 🏳️‍⚧️ XLibre-overlay: Transformation of the (already Trans) Xorg server in NixOS 💪
![logo](https://codeberg.org/takagemacoed/Screenshots/raw/branch/main/7dcfb685-cb14-4e2f-ba22-4870a131f2e2.jpg "Screenshots")

# Warning!!!
This is an experimental WIP flake to overlay the package `xorg.xorgserver` with `xlibre-xserver`. It also inculde some X11 drivers overlay.

Things might change at any time and breaking changes may happeen to break previous configurations.

For now, this is mainly for my personal use. The quality of the code may not be good enough for everyone's machine.

**Please inspect the code before use.**

I am not good at NixOS software packaging. If you see something wrong, plesae help me.

Now the [mesonFlags for xlibre-xserver](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/overlays/xlibre-xserver.nix#L25-L77) is for linux only.

I have no idea how to automatically update the `src` of overlays. I just do it manually for now.

Please let me know if you have some idea.

# Status
`xlibre-xserver`: works (tested only on x86-64_linux).

Drivers: most successfully build (on x86-64_linux). Only `xlibre-xf86-input-evdev` and `xlibre-xf86-input-libinput` are tested.

All the available drivers overlay are listed in [./xlibre-drivers-overlay-choice.nix](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/xlibre-build-options/xlibre-drivers-overlay-choice.nix).

It triggers building all the packages depending on `xorg.xorgserver` after you run `nixos-rebuild`.

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
## Choose between two predefined drivers versions
All the drivers overlays are defined in [./overlays/drivers](https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/overlays/drivers).

Most of the drivers there have two predefined version of overlay to choose from. I just do it for fun.

One is from the latest tag on github (default), the other one is the latest tag right before the first xlibre tag was created (supposedly from xorg era) also from github.

It is optionl to choose between two predefined versions.

If it is untouched, it choose the latest tag on github by default (update manually by hand for now).

Extensive instructions of how to choose predefined version is located inside the comments section of `inputs` of `flake.nix`.

The idea is to use user define nix expression to replace the expression in flake.

In this case, to replace the `xlibre-drivers-overlay-choice` input using `inputs.xlibre-drivers-overlay-choice.follows`:
https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/flake.nix#L17-L20

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
Glamor is enabled by default, but it seem break the machine using `xf86videoati` driver (for now). It can be disabled just with the method above ("Choose between two predefined drivers versions" section), but in this case to replace `xlibre-xserver-build-options` input using `inputs.xlibre-xserver-build-options.follows`:

https://codeberg.org/takagemacoed/xlibre-overlay/src/commit/6f4500e13a242245adb0193819923425b2caae63/flake.nix#L21-L24

You can also find the example in:

https://codeberg.org/takagemacoed/machine-nixos/src/branch/main/flake.nix

https://codeberg.org/takagemacoed/machine-nixos/src/branch/main/xlibre-build-options/driver-choice.nix

https://codeberg.org/takagemacoed/machine-nixos/src/branch/main/xlibre-build-options/my-xlibre-xserver-build-options.nix

# Known issues
It breaks some packages that were deeply integrated with Xorg.

For example `tigervnc`, the way it was packaged included [some hardcoded xorg paths](https://github.com/NixOS/nixpkgs/blob/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec/pkgs/by-name/ti/tigervnc/package.nix#L69-L92). It assumed the source of `xorg.xorgserver` is a tarball, so `fetchFromGitHub` cannot be used. It failed to build against xlibre-xserver without modification.

# TODO
1. Darwin support.
2. Xnamespace `NixosModule` (After figured it out how to configure).

# Note
The overlays mostly use the nixpkgs functionality `overrideAttrs` to modify the original package if the xorg counterpart is available in nixpkgs. Therefore this flake's overlay is not the whole packaging of the packages, just some modification of them (in nixpkgs) to make them become xlibre. If the corresponding packages change/removed in nixpkgs, it would also affect this flakes' overlay.

I do it that way (for now) because xorg in nixpkgs does not always change. Also nixpkgs have a file in `pkgs/servers/x11/xorg/overrides.nix` that take care of multiple architectures or build cases. Overlaying with `overrideAttrs` affect it less and require less code, so it might help building `xlibre-xserver` into other architectures running NixOS. If some big change happens in nixpkgs' xorg, I may also bring those code into this flake and make it a true packages.

