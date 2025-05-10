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
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  systemd.services.NetworkManager-wait-online.enable = false; #YOLO

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.server = {
     isNormalUser = true;
     extraGroups = [ "wheel" "sudo" "docker" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       neovim
       neofetch
       git
     ];
   };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
   environment.systemPackages = with pkgs; [
     neovim 
     wget
   ];

  programs.neovim.configure = {
      customRC = ''
      set number
      set nowrap
      set cc=80
      set list
      set listchars=tab:→\ ,space:·,nbsp:␣,trail:•,eol:¶,precedes:«,extends:»
      if &diff
        colorscheme blue
      endif
    '';
    packages.myVimPackage = with pkgs.vimPlugins; {
      start = [ ctrlp ];
	    };
	  defaultEditor = true;
	  viAlias = true;
	  vimAlias = true;
  };

  # List services that you want to enable:

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
  	enable = true;
	setSocketVariable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable Tailscale
  services.tailscale.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  system.stateVersion = "24.11"; 

}

