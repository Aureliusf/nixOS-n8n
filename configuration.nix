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

   users.users.autossh-runner = {
    isSystemUser = true;
    group = "nogroup";
    home = "/var/empty"; # This user doesn't need a home directory.
  };  

  # Add github and Server keys every time

  programs.ssh.startAgent = true;

  users.users.server.openssh.authorizedKeys.keys = [ 
  	"/home/server/.ssh/github.pub" 
  	"/home/server/.ssh/vultr.pub" 
  ];


  # Enable the OpenSSH daemon.
  services.openssh = {
  	enable = true;
	settings = {
		PasswordAuthentication = true;
		PrintMotd = true;
	};
  };

  services.fail2ban = {
  	enable = true;
	maxretry = 3;
	bantime-increment.enable = true;
	ignoreIP = [
		"127.0.0.1/8"
		"10.0.0.174"
		"100.67.201.23"
	];
  };
	# SSH tunnel service

    systemd.services.autossh-reverse-tunnel = {
    description = "Persistent autossh reverse tunnel to base.org.es";

    # This service should start after the network is available.
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    # Service configuration
    serviceConfig = {
      # The user the service will run as. Do not run as root.
      User = "autossh-runner";

      # The full command to execute.
      # Note we point to the credential file with the `-i` flag.
      ExecStart = ''
        ${pkgs.autossh}/bin/autossh -M 0 -N \
          -o "ServerAliveInterval=30" \
          -o "ServerAliveCountMax=3" \
          -o "StrictHostKeyChecking=no" \
          -o "ExitOnForwardFailure=yes" \
          -R 7575:localhost:80 \
          linuxuser@base.org.es
      '';

      # Automatically restart the service if it fails.
      Restart = "always";
      RestartSec = "10s"; # Wait 10 seconds before restarting.
    };
  };

  # List packages installed in system profile. To search, run:
   environment.systemPackages = with pkgs; [
     neovim 
     wget
     htop
     tmux
     autossh
   ];

  # List services that you want to enable:

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
  	enable = true;
	setSocketVariable = true;
  };


  # Enable Tailscale
  services.tailscale.enable = true;



  # Networking
  # Enable SSH access in from Tailscale network 22
  # Enable http/s traffic to go through 80 and 443
  networking.firewall = {
	  enable = true;
	  trustedInterfaces = ["tailscale0"];
	  allowedUDPPorts = [config.services.tailscale.port];
	  allowedTCPPorts = [ 22 443 80];
  	
  };

  


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # Set up alias for Github ssh authorization on build
  programs.bash.shellAliases = {
	  githubssh = "eval '$(ssh-agent -s)'; ssh-add ~/.ssh/github";
  };

  # Set up alias to serve publicly
  programs.bash.shellAliases = {
	  serveItQueen = "autossh -M 0 -N -o 'ServerAliveInterval 30' -o 'ServerAliveCountMax 3' -R 7575:localhost:80 linuxuser@base.org.es";
  };


  system.stateVersion = "24.11"; 

}

