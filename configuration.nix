{ pkgs, lib, ... }: {

  # NOTE: xanmod kernel improves desktop responsiveness and reduces system
  # latency, but could have some stability issue 
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernelParams = [ "copytoram" ];
  boot.supportedFilesystems =
    pkgs.lib.mkForce [ "btrfs" "vfat" "xfs" "ntfs" "cifs" ];

  system.stateVersion = "24.11";

  environment.defaultPackages = [ ];
  environment.systemPackages = with pkgs; [ electron cage ];

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "uk";

  services.cage.enable = true;
  services.cage.program =
    "${pkgs.electron}/bin/electron https://www.google.com";

  systemd.services.cage-tty1 = {
    # confirm network connection is active before running
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Environment = [
        # Prevent cage failing when no input devices are present
        "WLR_LIBINPUT_NO_DEVICES=1"
        # REVISIT: Use x11 BE instead of Wayland
        # firefox starts with black screen otherwise
        "MOZ_ENABLE_WAYLAND=0"
        # Better touch response and gesture support for touchscreens
        "MOZ_USE_XINPUT2=1"
      ];
    };
  };

  services.cage.user = "kiosk";
  users.users.kiosk.isNormalUser = true;

  users.users.root.initialHashedPassword = "";

  services.getty.loginProgram = "${pkgs.coreutils}/bin/true";

  # The system cannot be rebuilt.
  nix.enable = false;
  # The system is static.
  users.mutableUsers = false;
}
