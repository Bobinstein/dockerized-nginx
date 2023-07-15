# Dockerized NGINX with Let's Encrypt

This repository provides a Docker setup for NGINX with automatic SSL certificate generation using Let's Encrypt's Certbot. This setup is designed to be easily run on a windows computer. Wildcard domain certificates must be obtained manually, so the automated portion of this setup will only obtain a certificate for your base domain. Follow additional steps below to manually obtain wildcard certificates if needed for your project.

NOTE: This process is designed to only get a certificate for the base domain initially, this does not include a www prefix. The www prefix can be handled by wildcard certificates.

## Prerequisites

- Docker: Ensure Docker is installed on your system. You can download Docker Desktop for Windows from [here](https://www.docker.com/products/docker-desktop).
- Domain: You need a registered domain name that you can configure. This setup does not support IP addresses.
- GitHub CLI: To install GitHub CLI on your Windows system, follow these steps:
    - Download the latest GitHub CLI release from the [GitHub CLI repo](https://github.com/cli/cli/releases/tag/v2.31.0). Choose the .msi installer for Windows.
    - Once downloaded, run the .msi installer and follow the instructions to install GitHub CLI on your system.
    - After installation, you can verify the installation by opening a new command prompt or PowerShell window and typing `gh --version`. This should display the installed version of GitHub CLI.

## Setup Instructions

1. **Clone the repository**

   Clone this repository to your local machine. You can do this by running the following command in your terminal:

   ```
   gh repo clone bobinstein/dockerized-nginx
   ```

2. **Set up the .env file**

   In the root of the project, open the file named `.env`. This file will hold your domain name and email address.


   Replace `yourdomain.com` with your actual domain and `youremail@domain.com` with your actual email address.

   Your email address is used to receive messages from letsencrypt regarding your ssl certificates, including expiration warnings.


3. **Direct your domain at your home network**

    The instructions for this step will vary depending on what dns provider you used to purchase your domain. Most dns providers will offer access to C panel, if yours does you can follow these steps:

    - Open your C panel
    - Navigate to "Zone Editor" under the "Domains" section
    - Find your domain from the list on the left and click on "+ A Record"
        - This will ask for a name and ip address. In the name section put your domain (\<your-domain.com>)
        - In the ip address section, put your public ipv4 address. You can find this [here](https://whatismyipaddress.com/)
        - If you want to set up wildcard domains, create a new A Record with the name *.<your-domain.com> and the same ip address.


4. **Set up Port Forwarding on your router**

    - Find your local IP address
        - Open a command prompt or powershell window and run `ipconfig`
        - This will list information for all networks that may be attached to your computer
        - If you are connected to the internet over wifi, look for "Wireless LAN adapter Wi-Fi:"
        - Find the value for "IPv4 Address"
    - Open your router's admin page
        - The steps for this will vary depending on the make and model of your router, but generally you can go to `192.168.0.1` in your browser.
        - Once logged in, find the screen for creating port forwarding rules. This is generally under an "Advanced" tab.
        - Create 2 rules, one for port 80 and another for port 443. Both rules should take traffic from that port and forward it to the same port at your local ip address.

5. **Initialize the Docker container**

   Open a terminal in the project's root directory and run:

   ```
   docker-compose up --build
   ```

   This command will start the Docker container. The first time you run it, Docker will build the image based on the Dockerfile in the project.


- If you do not need wildcard certificates, you are done. Follow the next step to obtain, or renew, wildcard certificates which must be obtained manually.


6. **Obtain wildcard certificates**

   You need to manually obtain certificates for a wildcard domain. To do this, open a terminal in the running Docker container.

   First, find the container ID by running:

   ```
   docker ps
   ```

   This will list all running Docker containers. Identify the container running your nginx service, and copy its container ID.

   Then, open a terminal in the container by running:

   ```
   docker exec -it <CONTAINER_ID> /bin/bash
   ```

   Replace `<CONTAINER_ID>` with your actual container ID.

   Once you're in the container's terminal, run:

   ```
   certbot certonly --manual --preferred-challenges dns --email your-email@example.com -d "*.yourdomain.com"

   ```

   Replace `<yourdomain.com>` with your actual domain name and `your-email@example.com` with the email address you want to receive notices about your certificate. Let's Encrypt will email you a warning when it's time to renew your certificate. 

   The process will prompt you to create a TXT record for your domain in order to verify that you own it. This can be done in a similar way to how you created your A records earlier. Be sure to wait a minute after creating the record before continuing the prompt in your terminal to ensure that the new record propagates fully.

Please note that Let's Encrypt certificates expire after 90 days. The certificate for your base domain will be renewed automatically, but you will need to renew your wildcard certificates manually by following the same steps listed above for obtaining them initially.
