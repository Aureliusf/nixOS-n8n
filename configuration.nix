# n8n-server n8n through docker and served publicly through an ssh tunnel
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "n8n-server"; 

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  systemd.services.NetworkManager-wait-online.enable = false; #YOLO

  # Set your time zone.
  time.timeZone = "America/New_York";

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
    group = "wheel";
    home = "/home/autossh-runner";
    createHome = true; # <--- ADD THIS
  };

   users.users.backup = {
    isSystemUser = true;
    group = "nogroup";
    home = "/var/empty"; # This user doesn't need a home directory.
  };  

  users.users.komodo = {
    isSystemUser = true;
    uid = 1002;             # Static UID so we can use it in Compose
    group = "komodo";
    extraGroups = [ "docker" ]; 
    createHome = true;     
    home = "/home/komodo";
  };

  users.groups.komodo = {
    gid = 1002;
  };

  users.groups.docker.gid = 131;

  systemd.tmpfiles.rules = [
    "A+ /var/run/docker.sock - - - - u:232073:rw"
  ];

  # Add github and Server keys every time

  # SSH configs
  programs.ssh.startAgent = true;

  # Add github and public facing server keys every time

  users.users.server.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIwBDrGxREitq7swtiMea2Q5cuhtcgqLJRcptqDxlZXc aurelio@florezdelvalle.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGghZlBZXq467Dj/TLX4gyiwqAVwpc9T8KLuow5G8VS"
  ];

  users.users.autossh-runner.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGghZlBZXq467Dj/TLX4gyiwqAVwpc9T8KLuow5G8VS"
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # only key pairs 🔑
      PrintMotd = true;
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime-increment.enable = true;
    ignoreIP = [
      "127.0.0.1/8" # local machine traffic
      "10.0.0.174" # local network traffic
      "100.64.0.0/10" # local tailscale traffic
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
      ExecStart = ''
        ${pkgs.autossh}/bin/autossh -M 0 -N \
          -o "ServerAliveInterval=30" \
          -o "ServerAliveCountMax=3" \
          -o "StrictHostKeyChecking=yes" \
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

  # docker virtualisation

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Enable Tailscale
  services.tailscale.enable = true;

  # Networking
  # Enable SSH access in from Tailscale network 22
  # Enable http/s traffic to go through 80 and 443 for access n8n thorugh tailscale
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
    allowedTCPPorts = [22 443 80];
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # Set up alias to serve publicly 🧚
  programs.bash.shellAliases = {
    serveItQueen = "autossh -M 0 -N -o 'ServerAliveInterval 30' -o 'ServerAliveCountMax 3' -R  7575:localhost:80 linuxuser@base.org.es";
    githubssh = "eval '$(ssh-agent -s)'; ssh-add ~/.ssh/github";
  };


  # NAS mounting
  fileSystems."/storage/nfs" = {
    device = "florencia-storage.taild6c47b.ts.net:/mnt/all/server-storage";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];
  };


  # Backups

    systemd.services.n8n-backup = {
    description = "Backup n8n Docker data via rsync";
    script = ''
      # The -a flag includes -r (recursive), so we don't need both.
      # The --delete flag makes the destination an exact mirror.
      rsync -a --delete /n8n/data/ /storage/nfs/n8n/
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "backup";
    };
  };

  systemd.timers.n8n-backup = {
    description = "Run n8n backup nightly";
    timerConfig = {
      OnCalendar = "03:00"; # Runs daily at 3:00 AM
      Persistent = true;   # Runs on next boot if the system was off at 3 AM
    };
    wantedBy = [ "timers.target" ];
  };

  system.stateVersion = "25.11";
}
