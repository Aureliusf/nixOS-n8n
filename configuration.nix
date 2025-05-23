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
     extraGroups = [ "wheel" "sudo" "docker" "serveo-key" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       neofetch
       git
     ];
   };
   users.users.web= {
    isNormalUser = true;
    description = "Webapp SSH Tunnel User";
    home = "/home/web";
    extraGroups = [ "serveo-key" ]; # Enable ‘sudo’ for the user.
    # Set shell to nologin to prevent shell access
    #shell = "/run/current-system/sw/bin/nologin";

    # Optional: restrict SSH commands via authorized_keys command=...
    # You can add this in your authorized_keys file if needed
  };

  # Add github and Serveo keys every time

  programs.ssh.startAgent = true;

  users.users.server.openssh.authorizedKeys.keys = [ 
  	"/home/server/.ssh/github.pub" 
  ];

  users.users.web.openssh.authorizedKeys.keys = [ 
  	"/home/web/.ssh/serveo.pub" 
  	"/home/web/.ssh/sanlutex.pub" 
  	#"command='autossh'"
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

  systemd.services.autossh-tunnel = {
    description = "Persistent autossh tunnel for webapp";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''
        /run/current-system/sw/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -R -p 1020 8080:localhost:7575 baseorg@sanlutex.45st.com
      '';
      
      Restart = "always";
      User = "server";
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

  # Enable netbird
  services.netbird.enable = true;


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

  # Set up Github ssh authorization on build
  programs.bash.shellAliases = {
	  githubssh = "eval '$(ssh-agent -s)'; ssh-add ~/.ssh/github";
  };


  system.stateVersion = "24.11"; 

}

