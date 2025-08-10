#!/usr/bin/env nix
#! nix shell nixpkgs#bash --command bash

#https://nixos.org/manual/nix/stable/command-ref/new-cli/nix.html?highlight=shebang#shebang-interpreter

SYSTEM="$(uname -m)-linux"

CMD=(
  "nix build .#packages.$SYSTEM.xlibre-xserver"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-libinput"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-wacom"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-mouse"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-evdev"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-keyboard" # patched back the linux support
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-amdgpu"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-dummy"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-joystick"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-elographics"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-synaptics"
  "nix build .#packages.$SYSTEM.xlibre-xf86-input-void"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-ati"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-mga"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-nv"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-qxl"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-fbdev"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-nouveau"
  "nix build .#packages.$SYSTEM.xlibre-xf86-video-r128"
)

if [ "$SYSTEM" == "x86_64-linux" ]; then
  CMD+=(
    # Not in https://archlinuxarm.org/packages
    # meta in nixpkgs marked not for aarch64-linux
    "nix build .#packages.$SYSTEM.xlibre-xf86-video-intel"

    # Not in https://archlinuxarm.org/packages
    # meta in nixpkgs marked not for aarch64-linux
    "nix build .#packages.$SYSTEM.xlibre-xf86-video-vmware"

    # Not in https://archlinuxarm.org/packages
    # meta in nixpkgs marked not for aarch64-linux
    "nix build .#packages.$SYSTEM.xlibre-xf86-input-vmmouse"

    # xf86-video-ast - ASpeed Technologies graphics driver for Xorg X server
    # some intel thing
    # NOT in https://archlinuxarm.org/packages
    # "nix build nixpkgs\#xorg.xf86videoast" also build failed
    "nix build .#packages.$SYSTEM.xlibre-xf86-video-ast"

    # xf86-video-vesa - Generic VESA video driver for the Xorg X server
    # INSIDE https://archlinuxarm.org/packages
    # "nix build nixpkgs#xorg.xf86videovesa" also build failed
    "nix build .#packages.$SYSTEM.xlibre-xf86-video-vesa"

    # not in https://archlinuxarm.org/packages
    # "nix build nixpkgs\#xorg.xf86videogeode" : Package ‘xf86-video-geode-2.11.21’  is marked as broken
    "nix build .#packages.$SYSTEM.xlibre-xf86-video-geode"

    # Not in https://archlinuxarm.org/packages
    # meta in nixpkgs marked not for aarch64-linux
    "nix build .#packages.$SYSTEM.xlibre-xf86-video-siliconmotion"
  )
fi

for i in "${CMD[@]}"; do
  echo "Now running: $i"
  eval "$i"
  if [ $? -ne 0 ]; then echo "Error, exit build test." && exit 1; fi
done
