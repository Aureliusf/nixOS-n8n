# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "n8n-server"; # Define your hostname.
  # networking.wireless.enable = true;  
  networking.networkmanager.enable = true;  

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.server = {
     isNormalUser = true;
     extraGroups = [ "wheel" "docker" "sudo" ]; 
     packages = with pkgs; [
       tree
       neofetch
     ];
   };

  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim 
     wget
  ];

	# simple neovim config

	programs.neovim = {
	  enable = true;
	  configure = {
	    customRC = ''
	      set number
	      set nowrap
	      set cc=80
	      set list
	      set listchars=tab:→\ ,space:·,nbsp:␣,trail:•,eol:¶,precedes:«,extends:»
	    '';
	    packages.myVimPackage = with pkgs.vimPlugins; {
	      start = [ ctrlp ];
	    };
	  };
	  defaultEditor = true;
	  viAlias = true;
	  vimAlias = true;
	};


  # List services that you want to enable:
  services.tailscale.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  system.stateVersion = "24.11"; # Did you read the comment?

}

