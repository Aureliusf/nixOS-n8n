# Serve n8n with nixOS

I have seen Nix and NixOS all over the internet and see how people swear by them, as well as the rock-solid deployments they can offer.
When I wanted to look deeper into n8n, I took the opportunity to do both things at the same time: learn n8n and nix.

# n8n

n8n is a "Fair-code workflow automation platform with native AI capabilities". [n8n-io/n8n](https://github.com/n8n-io/n8n). My tldr; a better interface for Zapier that my father can finally use and 🪄 AI 🪄
n8n can be run with Docker and, more recently, with npx directly. Regrettably, I did not receive the memo in time and started this project with Docker instead before npx was a viable option.
nixOS is attractive because the entire system is declarative in its configuration. And if there are things you want to leave nondeclarative, you can do so with no problem!
Because the system is meant to be declarative, and dependencies are separately stored. You can even use different versions of packages on the same system without interfering. Due to this newfound capability with nixOS, the nix way to run services is not with a virtualization layer but directly on bare metal.
TBD will be transferred from Docker to running directly with npx.

To run the container, it worked right away. n8n needs SSL certificates to work correctly; other than that, I used the Docker compose on the docs, changing a couple of details and importing the DB secrets from an .env file

# nixOS

[nixOS](https://nixos.wiki/) is a Linux distribution based on the Nix package manager that uses an immutable design and an atomic update model. Its use of a declarative configuration system allows reproducibility, portability, and a light server.
After grabbing the GUI installer to start familiarizing myself with the new distro, I set up SSH keys and sshd service in the n8n-server machine to start treating it like a real server.
This is what I did to ensure ssh would be available every time the system boots and the right public keys are authorized. Furthermore, and to be better safe than sorry, fail2ban with some allowed local IPs.
```` nix
  # SSH configs
  programs.ssh.startAgent = true;

  # Add github and public facing server keys every time

  users.users.server.openssh.authorizedKeys.keys = [
    "/home/server/.ssh/github.pub"
    "/home/server/.ssh/vultr.pub"
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
      "100.67.201.23" # local tailscale traffic
    ];
  };
````

In order to have access to n8n-server even when not at home and in line with the rest of my homelab, tailscale
```` nix
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

`````
One of the first big issues I faced was losing my old configuration after I made breaking changes while trying to set up Docker properly. nixOS will always have a working build that is true and extremely useful. If you run nixOS, you will never have a broken system, period. However, if you lose your old `configuration.nix` because of a change that was not properly tracked, you have lost it.
To fix this, you can set up nixOS to copy your config files to the appropriate system generation directory.
````nix
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you accidentally delete configuration.nix.
  system.copySystemConfiguration = true;
`````

This setting works even in more complex multi-file configuration systems like in my regular dotfiles.

# Serve
The easiest and safest way I found to serve a locally hosted service through a public domain that can get Let's Encrypt SSL certificates is with an ssh tunnel. I started using Serveo, which worked great, BUT it would disconnect once a day, even when using autossh. For that, I had to move into hosting my public-facing server. 
I chose to use Vultr with the cheapest possible VPS. It runs nginx in an AlmaLinux system.
This is the flow for a given user:
````mermaid
graph TD
    A[Client Browser] -->|HTTP/S Request| B(base.org.es)
    B -->|"DNS Resolution (Vultr)"| C[Vultr Instance]
    C -->|"Nginx"| D{"Vultr Internal Port 7575"}
    D -->|"SSH Tunnel (Vultr Side)"| E((SSH Tunnel))
    E -->|"SSH Tunnel (Local Side)"| F[Local nixOS n8n-server]
    F -->|"Local Port Forwarding"| G(n8n container)

    subgraph Vultr Infrastructure
        C
        D
    end

    subgraph Local Infrastructure
        F
        G
    end

    %% Flow Explanations
    click A "User's browser initiates request"
    click B "Domain resolves to Vultr IP via DNS"
    click C "Nginx on Vultr instance receives request"
    click D "Nginx reverse proxies to internal Vultr port 7575"
    click E "SSH tunnel securely forwards traffic from Vultr port 7575 to your local machine"
    click F "Local machine receives forwarded traffic from SSH tunnel"
    click G "n8n server receives traffic on its local port"

````
This way, I don't need to open any ports in my local network or open my homelab this way. With this ssh tunnel, traffic should only be able to access what is served on the local port is pointed to and nothing else.
This means that I am unable to ssh into my n8n-server through base.org.es at all, even though sshd is running, even from one of the allowed IPs.
