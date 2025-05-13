# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./nvim.nix
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


  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.server = {
     isNormalUser = true;
     extraGroups = [ "wheel" "sudo" "docker" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       neofetch
       git
     ];
   };

  # List packages installed in system profile. To search, run:
   environment.systemPackages = with pkgs; [
     neovim 
     wget
     htop
     tmux
   ];

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

  # Enable Nginx service
  services.nginx.enable = true;

  services.nginx.virtualHosts."base.org.es" = {
  	enableACME = true;
	serverNames = [
		"base.org.es"
		"n8n-server.taild6c47b.ts.net"
		"100.127.235.99"
	];

  services.nginx.acme.email = "aurelio@florezdelvalle.com";
  services.nginx.acme.acceptTerms = true;

	forceSSL = true;

	    # Configure the proxy pass to your Docker container on port 80
    locations."/" = {
      proxyPass = "http://0.0.0.0:80"; # Assuming docker is on the same host
      # Optional: Add proxy headers
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };

    # Optional: Configure logging
    accessLog.enable = true;
    errorLog.enable = true;

  };


  # Allow traffic into 443 and 80
  networking.firewall.allowedTCPPorts = [ 80 443 ];



  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  system.stateVersion = "24.11"; 

}

