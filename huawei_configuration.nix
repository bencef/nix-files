# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <musnix>
    ];

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/f8704de7d8dd727af1b180bcf6166f5c40e4063a.tar.gz;
    }))
    (final: prev: {
      my-emacs-git =
        (prev.emacsPackagesFor
          ((prev.emacs-git.overrideAttrs
            (old: { withTreeSitter = true; }))
          )).emacsWithPackages (epkgs: with epkgs; [
            vterm
            (treesit-grammars.with-all-grammars)
          ]);
    })
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "huawei"; # Define your hostname.
  networking.wireless = {
    enable = true;  # Enables wireless support via wpa_supplicant.
    interfaces = [ "wlp1s0" ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp1s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  fonts = {
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      source-code-pro
      victor-mono
      # corefonts
    ];
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = false;
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5 = {
      enable = true;
      useQtScaling = true;
    };
  };


  # Enable the Plasma 5 Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;


  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable avahi for service discovery
  services.avahi = {
    enable = true;
    openFirewall = true;
  };

  # Enable using local dictionary databases
  services.dictd.enable = true;

  # patch CPU microcode
  hardware.cpu.amd.updateMicrocode = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
  };

  # Enable bluetooth service but don't turn on the node on boot
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # musnix = {
  #   enable = true;
  #   kernel = {
  #     realtime = true;
  #   };
  # };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 exclusive_caps=1
  '';

  # TODO: This is fixed upstream.  Remove it when applicable
  # Without this 5.19 doesn't see the touchpad
  boot.kernelPatches = [ {
    name = "touchpad-config";
    patch = null;
    extraConfig = ''
      PINCTRL_AMD y
    '';
  } ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [ amdvlk ];
    extraPackages32 = with pkgs.pkgsi686Linux; [ amdvlk ];
  };

  # Enable screen sharing on wayland
  xdg.portal.wlr.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable joycon support
  services.joycond.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    bence = {
      isNormalUser = true;
      extraGroups = [ "wheel" "audio" "video" "sway" "docker" "disk" ];
    };
    work = {
      isNormalUser = true;
      extraGroups = ["audio" "video" "sway"];
    };
  };

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; let
    browsers = [
      chromium
      firefox-wayland
    ];
    audio = [
      ardour
      guitarix
      qpwgraph
    ];
    utilities = [
      diction
      file
      git
      inotify-tools
      ispell
      lsof
      p7zip
      plan9port
      poppler_utils
      ripgrep
      unzip
      wget
    ];
    games = [
      steam
      # Needed for winetricks to be able to download via HTTPS
      (lutris.override { extraPkgs = pkgs: [pkgs.cacert pkgs.openssl]; })
    ];
    media = [
      pavucontrol
      ffmpeg
      gimp
      krita
      mpv
      (wrapOBS { plugins = with obs-studio-plugins; [
                   wlrobs
                   obs-pipewire-audio-capture
                 ]; })
    ];
    devTools = [
      (boot.override({ jdk = jdk11_headless; }))
      docker-compose
      my-emacs-git
      (vscodium-fhsWithPackages (p: [p.dotnet-sdk_7]))
    ];
    documents = [
      mupdf
      ghostscript
      plantuml
    ];
  in audio ++ browsers ++ utilities ++ games ++ media ++ devTools ++ documents ++ [
    qt5.qtwayland # See note in sway session config
    alsaOss # TODO: what needs this?
    gnome3.adwaita-icon-theme # For icons in some apps for example lutris
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs = {
    firejail.enable = true;
    sway = {
      enable = true;
      extraSessionCommands = ''
        export XKB_DEFAULT_LAYOUT=us
        export XKB_DEFAULT_OPTIONS=ctrl:nocaps
        export SDL_VIDEODRIVER=wayland
        # needs qt5.qtwayland in systemPackages
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
        export MOZ_ENABLE_WAYLAND=1
        export PATH="$HOME/bin:$PATH"
      '';
      extraPackages = with pkgs; [
        i3status xwayland alacritty dmenu qt5.qtwayland swaylock
        swayidle wl-clipboard
      ];
    };
  };

  # List services that you want to enable:

  # Enable docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune.enable = true;
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 3000 5000 7000 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
