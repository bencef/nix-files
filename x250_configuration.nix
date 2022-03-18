# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./musnix
    ];

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  musnix = {
    enable = true;
    kernel = {
      optimize = true;
      realtime = true;
      packages = pkgs.linuxPackages_latest_rt;
    };
  };

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "rw" "relatime" ];
  };

  networking = {
    hostName = "x250"; # Define your hostname.
    wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    wireless.interfaces = [ "wlp3s0" ];
    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Open ports in the firewall.
    firewall = {
      allowedTCPPorts = [ 3000 5000 7000 ];
      allowedUDPPorts = [ ];
      # Or disable the firewall altogether.
      # enable = false;
    };
  };

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Fonts
  fonts = {
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      source-code-pro
      victor-mono
      corefonts
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Budapest";

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  };

  hardware.cpu.intel.updateMicrocode = true;

  nixpkgs.config = {
    allowUnfree = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    let
      lv2Plugins = [
        calf
        eq10q
        speech-denoiser
        infamousPlugins
        fmsynth
        guitarix
        swh_lv2
        mda_lv2
      ];
    in
      lv2Plugins ++ [
        alsaOss
        (alsaPlugins.override {inherit libjack2;})
        pkgsi686Linux.apulse
        ardour
        blender
        (boot.override { jdk = jdk11_headless; })
        bs-platform
        chromium
        # dmenu2
        docker-compose
        dosbox
        dotnet-sdk_3
        dzen2
        ed
        (emacsGcc.override {
          inherit imagemagick;
          # withXwidgets = true;
        })
        fbreader
        feh
        ffmpeg
        file
        # (wrapFirefox (firefox-unwrapped.override { pulseaudioSupport = false; }) { gdkWayland = true; })
        firefox-wayland
        firejail
        ghostscript
        gimp
        git
        gnumake
        go-mtpfs
        inotify-tools
        jack2Full
        jq
        lutris
        obs-studio
        pavucontrol
        kvm
        kubectl
        ledger
        maxima
        minikube
        moc
        (wrapMpv (mpv-unwrapped.override { jackaudioSupport = true; }) {})
        mupdf
        ntfs3g
        p7zip
        pharo-spur32
        plan9port
        plantuml
        poppler_utils
        qjackctl
        racket
        ripgrep
        rtorrent
        rxvt_unicode
        samba
        sbcl
        sbt
        scala
        simplescreenrecorder
        slock
        sshfsFuse
        steam
        trash-cli
        wesnoth
        wget
        wine
        winetricks
        wireshark
        x11_ssh_askpass
        xclip
        xcompmgr
        xlibs.xsetroot
        xorg.xhost
        xorg.xmessage
        haskellPackages.xmobar
        xorg.xmodmap
      ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs = {
    firejail.enable = true;
    slock.enable = true;
    java.enable = true;
    chromium.enable = true;
    # gnupg.agent = { enable = true; enableSSHSupport = true; };
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
        i3status xwayland termite dmenu qt5.qtwayland swaylock
      ];
    };
  };

  security = {
    sudo.enable = true;
    wrappers = with pkgs; {
      go-mtpfs.source = "${go-mtpfs}/bin/go-mtpfs";
    };
    # Needed for wine
    pam.loginLimits = [
      { domain = "bence";
        type = "hard";
        item = "nofile";
        value = "524288";
      }
    ];
  };

  # use private tmp folders for nix
  systemd.services.nix-daemon.serviceConfig.PrivateTmp = true;

  # List services that you want to enable:

  virtualisation.docker.enable = true;

  # Enable libvirt
  virtualisation.libvirtd.enable = true;

  # Enable service discovery
  services.avahi = {
    enable = true;
    ipv6 = true;
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages =
    let
      v4l2loopback = with pkgs; lib.overrideDerivation config.boot.kernelPackages.v4l2loopback (oldAttr: rec {
        version = "0.12.5";

        src = fetchFromGitHub {
          owner = "umlaeute";
          repo = "v4l2loopback";
          rev = "v${version}";
          sha256 = "1qi4l6yam8nrlmc3zwkrz9vph0xsj1cgmkqci4652mbpbzigg7vn";
        };

      });
    in [
      v4l2loopback
    ];
  boot.extraModprobeConfig = "options v4l2loopback devices=1 exclusive_caps=1";

  # enable sound.
  sound.enable = true;
  # hardware.pulseaudio.enable = true;
  # boot.blacklistedKernelModules = [
  #   "snd_hda_codec_hdmi"
  # ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    jack.enable = true;
    pulse.enable = true;
  };


  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us";
    wacom.enable = true;
    synaptics = {
      enable = true;
      tapButtons = false;
      palmDetect = true;
    };
    libinput.enable = false;
    windowManager.xmonad = {
      enable = true;
      extraPackages = haskellPackages: [
        haskellPackages.xmonad-contrib
      ];
      enableContribAndExtras = true;
    };
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager.lightdm.enable = true;
    displayManager.defaultSession = "none+xmonad";
    displayManager.sessionCommands = with pkgs; ''
      # ${jack2Full}/bin/jack_control start
      export SUDO_ASKPASS=${x11_ssh_askpass}/libexec/x11-ssh-askpass
      ${trash-cli}/bin/trash-empty 7 &
      ${xcompmgr}/bin/xcompmgr &
      [ -d ~/lib/bg ] && ${feh}/bin/feh --bg-center ~/lib/bg/`ls lib/bg/ | sort -R | sed 1q`
      ${xlibs.xsetroot}/bin/xsetroot -cursor_name left_ptr
      [ -f ~/.Xmodmap ] && ${xorg.xmodmap}/bin/xmodmap ~/.Xmodmap
      ${xorg.xhost}/bin/xhost local:docker
    '';
  };

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers = {
    bence = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "audio" "video" "sway"
                      "docker" "libvirtd" "disk" ];
    };
    eniko = {
      isNormalUser = true;
      uid = 1001;
      extraGroups = [ "audio" "video" "docker" "disk" ];
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09";

}
