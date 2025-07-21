{
  # No matter setting it to true or false, the drivers are pull
  # from https://github.com/X11Libre if you use the drivers overlay
  #
  # If set it to true, it use the latest tag from xlibre github.
  # If set to false, it use the tag rigth before latest xlibre tag was created
  # If old tags are not available/failed to build against xlibre-xserver,
  # setting true or false is the same as true because there is only one choice
  # The true/false will pass into the "USE-XLIBRE-VERSION-DRIVER" variable in
  # the drivers overlays.
  # Browse through `./overlays/drivers` for more details of the revision it
  # actually use.

  xlibre-xf86-input-elographics = true; # nixpkgs do not have this package
  xlibre-xf86-input-evdev = true;
  xlibre-xf86-input-joystick = true;
  xlibre-xf86-input-keyboard = true; # patched back the linux support in both tags (true or false)
  xlibre-xf86-input-libinput = true;
  xlibre-xf86-input-mouse = true; # patch back the linux support in the latest tag (true)
  xlibre-xf86-input-synaptics = true; # There is no xlibre tag for this driver, so true/false also point to the same latest tag for now
  xlibre-xf86-input-vmmouse = true;
  xlibre-xf86-input-void = true;
  xlibre-xf86-input-wacom = true; # patch back the linux support in both tags (true or false)
  xlibre-xf86-video-amdgpu = true;
  xlibre-xf86-video-ast = true; # for now there is no xlibre tag for this driver. true/false all point to latest tag
  xlibre-xf86-video-ati = true;
  xlibre-xf86-video-dummy = true;
  xlibre-xf86-video-fbdev = true;
  xlibre-xf86-video-geode = true;
  xlibre-xf86-video-intel = true; # old tag failed to build against xlibre-xserver. true/false all point to latest tag
  xlibre-xf86-video-mga = true;
  xlibre-xf86-video-nouveau = true;
  xlibre-xf86-video-nv = true;
  xlibre-xf86-video-qxl = true; # Only one tag is available. true/false all point to latest tag
  xlibre-xf86-video-r128 = true;
  xlibre-xf86-video-siliconmotion = true; # old tag failed to build against xlibre-xserver. true/false all point to latest tag
  xlibre-xf86-video-vesa = true;
  xlibre-xf86-video-vmware = true;
}
