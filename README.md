## Kiosk on a stick

_View actions for build artifact_


The goal of this project is to create a basic OS image that runs a binary via [cage](https://github.com/cage-kiosk/cage). In this repository, I have chosen to link to Firefox in kiosk mode with Google as the address. However, this could be linked to a binary built within the repository itself.

### Intended usage with a browser

Within a show environment having a central server in the backoffice which all computers running "Kiosk on a stick" connect to and display the site.

## Pros

- The system is entirely locked down. If a site guest manages to exit the running program, there is no window manager or operating system to access, and a reboot would bring the guest back into the running binary
- Consistent and immutable, as mentioned above, any changes within the binary can be resolved with a reboot
- Predictable programs, unlike Windows, there are no upgrade popups to display
- Fast boot times
- Issues can be recreated away from site by running an exact copy of the same image anywhere
- The image is copied to RAM, which means that one USB drive can be used to load multiple devices

## Cons

- No runtime updates, system updates require a full image deployment and device restart
- Limited flexibility, making changes will require rebuilding the image

## Q&A

### Set unique hostname per device

Due to the image being entirely static a simple approach would be to create many images with unique hostnames configured

```nix
networking.hostName = "your-hostname";
```

Alternatively you can use DHCP to set the hostname


```nix
networking = {
  hostName = "your-hostname"; # Fallback hostname
  dhcpcd.enable = true;          # Enable the DHCP client
  dhcpcd.hostname = "";          # Empty string means accept hostname from DHCP
};
```

### Connect to wifi

```nix
networking.wireless = {
  enable = true;  # Enable wireless support
  networks = {
    "SSID" = {
      psk = "your-password";
    };
  };
};
```

### Copy to a USB device

**Be careful, as you can potentially wipe your own hard drive**

Note that it doesnt have to be copied to a USB device exclusively. The image contains default nixos configuration specifically [All Hardware](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/all-hardware.nix).


```bash
$ lsblk # get list of all attached devices (may start with /dev/sdX)
$ dd if=/image.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### Bake local files into the image


_This does not have to be an index.html file, and Cage does not have to run Firefox. You could build a binary in CI and copy it to the system_

Copy your index.html to a default www location

```nix
  system.activationScripts = {
    copyWebFiles = {
      text = ''
        mkdir -p /var/www/html
        cp ${./index.html} /var/www/html/index.html
        chmod 644 /var/www/html/index.html
      '';
    };
  };
```

Update cage to point at the local file

```nix
  services.cage.program =
    "${pkgs.firefox}/bin/firefox -kiosk file:///var/www/html/index.html";
```

## Build locally

```bash
nixos-generate -f raw -o result -c configuration.nix
```

## Run in a VM

```bash
qemu-system-x86_64 \        
 -boot order=d \           # Boot from CD/DVD first  
 -device usb-ehci,id=usb \ # Create USB controller
 -device usb-storage,drive=usbdisk \ # Create USB storage device
 -drive file=./nixos.img,format=raw,if=none,id=usbdisk \ # Specify disk image
 -enable-kvm \             # Enable KVM hardware virtualization
 -m 8G \                   # Allocate 8GB RAM
 -smp 2                    # Configure 2 CPU cores
```

## Research

- https://github.com/cage-kiosk/cage/wiki/Troubleshooting#touch-input-isnt-transformed-correctly-to-my-transformed-touch-output
