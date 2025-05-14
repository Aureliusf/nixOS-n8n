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
   users.users.web= {
    isNormalUser = true;
    description = "Webapp SSH Tunnel User";
    home = "/var/lib/web";
    # Set shell to nologin to prevent shell access
    shell = "/run/current-system/sw/bin/nologin";

    # Optional: restrict SSH commands via authorized_keys command=...
    # You can add this in your authorized_keys file if needed
  };

  # Add github and Serveo keys every time
  environment.etc."ssh/authorized_keys" = {
    source = ''
      ${builtins.readFile "/home/server/.ssh/github.pub"}
      ${builtins.readFile "/home/server/.ssh/serveo.pub"}
    '';
  };

  systemd.services.autossh-tunnel = {
    description = "Persistent autossh tunnel for webapp";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''
        /run/current-system/sw/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -R ssh -R n8n-i4nm:80:localhost:80 n8n-i4nm@serveo.net
      '';
      
      Restart = "always";
      User = "web";
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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable Tailscale
  services.tailscale.enable = true;


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

