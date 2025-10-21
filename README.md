# Server Config

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

---

> **⚠️ ARCHIVED REPOSITORY**
>
> This repository has been archived and is no longer maintained. The server configuration has been migrated to a full NixOS declarative setup.
>
> **Please visit the new repository:** [ThomasRitaine/nixos-config](https://github.com/ThomasRitaine/nixos-config)

---

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/ThomasRitaine/server-config">
    <img src="docs/images/logo.webp" alt="Logo" width="175" height="175">
  </a>

<h3 align="center">Server Config</h3>

  <p align="center">
    A containerized server setup using NixOS for declarative configuration, advanced security, and backup features for personal production use.
    <br />
    <a href="https://github.com/ThomasRitaine/server-config"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://thomas.ritaine.com">View Demo</a>
    ·
    <a href="https://github.com/ThomasRitaine/server-config/issues">Report Bug</a>
    ·
    <a href="https://github.com/ThomasRitaine/server-config/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#server-setup">Server Setup</a></li>
        <li><a href="#project-installation">Project Installation</a></li>
        <li><a href="#environment-variables">Environment Variables</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a>
      <ul>
        <li><a href="#deploying-apps-with-docker-behind-traefik">Deploying Apps with Docker Behind Traefik</a></li>
        <li><a href="#configuring-the-backup-system">Configuring the Backup System</a></li>
        <li><a href="#accessing-admin-endpoints">Accessing Admin Endpoints</a></li>
        <li><a href="#custom-error-pages">Custom Error Pages</a></li>
      </ul>
    </li>
    <li><a href="#folder-structure">Folder Structure</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

[![The server's terminal][server-terminal]](https://thomas.ritaine.com)

A containerized server setup using NixOS for declarative configuration, advanced security, and backup features for personal production use:

- **NixOS Declarative Configuration**: Utilizes NixOS for its declarative configuration, providing stability and ease of management for VPS environments.
- **Dockerized Applications**: Applications run in Docker containers, making deployment easy and ensuring they don't interfere with each other.
- **Advanced Security**: Incorporates SSH key-based logins and Fail2Ban to enhance server security.
- **Automated Backups**: Scheduled backup script to archive directories and Docker volumes to any S3-compatible storage.
- **Single Sign-On (SSO)**: Uses Authentik as an SSO provider for secure access to administrative applications.
- **Custom Error Handling**: Displays custom error pages instead of default Traefik error pages.
- **Documentation-Driven**: Detailed installation and setup guides to streamline the server configuration process.

This setup is tailored for developers looking for a secure and maintainable server environment for their personal projects.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

The server configuration leverages a variety of technologies for security, orchestration, and automation:

- [![NixOS][NixOS-shield]][NixOS-url]
- [![Docker][Docker-shield]][Docker-url]
- [![Traefik][Traefik-shield]][Traefik-url]
- [![Authentik][Authentik-shield]][Authentik-url]
- [![Zsh][Zsh-shield]][Zsh-url]
- [![Bash][Bash-shield]][Bash-url]
- [![Amazon S3][S3-shield]][S3-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

This project contains all the necessary configurations to set up a secure, containerized server environment using NixOS for personal production use.

### Prerequisites

- A VPS capable of running NixOS (or a VPS hosting provider that allows you to upload your own ISO image). Personally, I use a [Netcup](https://www.netcup.com/) VPS.
- Basic knowledge of Docker, Linux commands, and server security concepts.

### Server Setup

1. **Install NixOS on Your VPS**: Follow the NixOS installation guide to set up NixOS on your VPS. The declarative configuration of NixOS is well-suited for stable VPS environments.

2. **Server Configuration**: Configure your server using the provided NixOS configuration files and instructions in `docs/install.md`. This includes setting up users, SSH keys, and necessary services.

### Project Installation

Once the server is ready, proceed with the installation of this repository by following the steps in `docs/install.md`. This includes cloning the repository, setting up environment variables, and deploying services via Docker.

For full installation instructions, please refer to the documentation:

- [Installation Guide](docs/install.md)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Environment Variables

For this setup to work properly, you will need to set several environment variables. These variables should be set in a `.env` file that you create based on the provided `.env.example` file. Here is a list of the required environment variables and their descriptions:

| Variable Name    | Description                                             | Example Value                           |
| ---------------- | ------------------------------------------------------- | --------------------------------------- |
| `DOMAIN_NAME`    | The domain name where your services will be hosted.     | `example.com`                           |
| `S3_BUCKET_NAME` | The name of the S3 bucket used for backups.             | `my-backup-bucket`                      |
| `S3_ENDPOINT`    | The endpoint URL for the S3-compatible storage service. | `https://s3.eu-central-1.amazonaws.com` |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->

## Usage

Once your server configuration is set up, deploying applications and managing the server is straightforward.

### Deploying Apps with Docker Behind Traefik

Here are two simple examples to deploy apps with Traefik:

#### Example 1: Expose an App

```yaml
services:
  webapp:
    image: nginx
    networks:
      - traefik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`webapp.example.com`)"

networks:
  traefik:
    external: true
```

This configuration makes the app accessible at `https://webapp.example.com` if the DNS record points to your VPS.

---

#### Example 2: Protect an App with Authentication

```yaml
services:
  secure-app:
    image: nginx
    networks:
      - traefik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.secure-app.rule=Host(`secureapp.${DOMAIN_NAME}`)"
      - "traefik.http.routers.secure-app.middlewares=auth-require-login@file,auth-require-group-admin-vps@file"

networks:
  traefik:
    external: true
```

This configuration requires users to authenticate via Authentik and belong to the `admin-vps` group to access `https://secureapp.<DOMAIN_NAME>`.

Replace the service name, image, and `DOMAIN_NAME` as needed. Both examples connect to the Traefik network for reverse proxying.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Configuring the Backup System

To set up backups for your applications:

1. All directories inside `/home/app-manager/applications` are backed up to preserve configuration files like `.env` and `docker-compose.yml`.

2. To backup Docker volumes associated with an application:

   - Create a `.backup` file within your application's directory.
   - Inside the `.backup` file, list the names of the Docker volumes you wish to backup, one per line.
   - Alternatively, use an asterisk `*` to backup all Docker volumes for that application.

The backup script will handle the creation and storage of archives according to this configuration. Backups are scheduled to run every night.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Accessing Admin Endpoints

The server uses Authentik as an SSO provider for secure access to administrative applications. The following admin endpoints are available (replace `example.com` with your `DOMAIN_NAME`):

- **Traefik Dashboard**: `https://traefik.example.com`
- **DBeaver**: `https://dbeaver.example.com`

These endpoints require authentication via Authentik and are accessible only to authorized user groups.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Custom Error Pages

The setup includes custom error handling. Instead of displaying default Traefik error pages, users see customized pages with relevant error codes.

![Error Page for a 404 service not found][error-pages-screenshot]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- FOLDER STRUCTURE AND EXPLANATIONS -->

## Folder Structure

Below is an overview of the key directories and files in this server configuration project:

```
.
├── authentik/                # Authentik SSO provider configuration.
│   ├── certs/                # Certificates for Authentik.
│   ├── custom-templates/     # Custom templates for Authentik.
│   ├── docker-compose.yml    # Docker Compose file to set up Authentik.
│   └── media/                # Media assets for Authentik.
├── backup/                   # Backup scripts and logs.
│   ├── cron_backup.sh        # The backup script.
│   ├── logs/                 # Directory in which backup script logs are written.
│   └── restore_backup.sh     # Script to restore backups.
├── dbeaver/                  # DBeaver Docker setup for database management.
│   ├── docker-compose.yml    # Docker Compose file to set up DBeaver.
│   └── workspace/            # Workspace for DBeaver configuration and data.
├── docs/                     # Project documentation and resources.
│   ├── images/               # Images used to illustrate the documentation.
│   └── install.md            # Installation guide for the project.
├── monitoring/               # Monitoring configuration files and Docker Compose.
├── nixos/                    # NixOS configuration files.
│   ├── configuration.nix     # Main NixOS configuration file.
│   └── zsh.nix               # Zsh configuration for NixOS.
├── traefik/                  # Traefik reverse proxy configuration.
│   ├── certificates/         # SSL Let's Encrypt certificates for HTTPS.
│   ├── config/               # Dynamic configuration.
│   │   ├── https.yml         # SSL layer and HSTS config.
│   │   └── middlewares.yml   # Middleware configurations.
│   ├── docker-compose.yml    # Docker Compose file to set up Traefik.
│   └── traefik.yml           # Static configuration for Traefik.
├── .env.example              # Example environment variables setup.
├── .gitignore                # Specifies files to be ignored by Git.
├── LICENSE                   # License for the project.
└── README.md                 # High-level project documentation.
```

This structure provides a clear and organized view of the various components of the server setup, from the reverse proxy to monitoring, backup systems, and NixOS configurations.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->

## Roadmap

This is a personal project, and its primary goal is not widespread popularity. As such, there is no formal roadmap for future features. The project will evolve based on my personal interests and the new technologies I wish to explore.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->

## Contributing

I welcome community involvement:

- **Issues**: Feel free to open issues to report bugs or request features.
- **Pull Requests**: Contributions via pull requests are also welcome.
- **Forking**: Feel free to fork and adapt the project as you like with proper credit.

Keep in mind that updates and new features will be implemented as per my discretion and interest in the technology.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Thomas Ritaine - [@ai_art_tv](https://twitter.com/ai_art_tv) - <thomas@ritaine.com>

Project Link: [https://github.com/ThomasRitaine/server-config](https://github.com/ThomasRitaine/server-config)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

Special thanks to the following resources and tools that have played a significant role in the development of this server configuration:

- [NixOS Community](https://nixos.org/) - For the powerful and declarative NixOS operating system, providing stability and ease of configuration.
- [Authentik](https://goauthentik.io/) - For the excellent SSO solution that simplifies authentication across services.
- [#Prox-i](https://www.prox-i.pf/) - A communication agency for whom the initial setup was developed, which inspired continuous improvement and led to the current configuration.
- [Docker](https://www.docker.com/) - For the containerization platform that makes it possible to isolate applications.
- [Traefik](https://traefik.io/) - For the excellent reverse proxy, ease of configuration, and automatic SSL setup.
- [Let's Encrypt](https://letsencrypt.org/) - For providing free SSL certificates to secure web communications.

This project wouldn't have been possible without these invaluable resources.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- Badges -->

[contributors-shield]: https://img.shields.io/github/contributors/ThomasRitaine/server-config.svg?style=for-the-badge
[contributors-url]: https://github.com/ThomasRitaine/server-config/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/ThomasRitaine/server-config.svg?style=for-the-badge
[forks-url]: https://github.com/ThomasRitaine/server-config/network/members
[stars-shield]: https://img.shields.io/github/stars/ThomasRitaine/server-config.svg?style=for-the-badge
[stars-url]: https://github.com/ThomasRitaine/server-config/stargazers
[issues-shield]: https://img.shields.io/github/issues/ThomasRitaine/server-config.svg?style=for-the-badge
[issues-url]: https://github.com/ThomasRitaine/server-config/issues
[license-shield]: https://img.shields.io/github/license/ThomasRitaine/server-config.svg?style=for-the-badge
[license-url]: https://github.com/ThomasRitaine/server-config/blob/master/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/thomas-ritaine
[server-terminal]: docs/images/server-terminal.webp
[error-pages-screenshot]: docs/images/error-pages-404.webp
[NixOS-shield]: https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white
[NixOS-url]: https://nixos.org/
[Docker-shield]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[Docker-url]: https://www.docker.com/
[Traefik-shield]: https://img.shields.io/badge/Traefik%20Proxy-24A1C1?logo=traefikproxy&logoColor=fff&style=for-the-badge
[Traefik-url]: https://traefik.io/
[Authentik-shield]: https://img.shields.io/badge/Authentik-FD4B2D?style=for-the-badge&logo=authentik&logoColor=white
[Authentik-url]: https://goauthentik.io/
[Zsh-shield]: https://img.shields.io/badge/Zsh-F15A24?logo=zsh&logoColor=fff&style=for-the-badge
[Zsh-url]: https://en.wikipedia.org/wiki/Z_shell
[Bash-shield]: https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white
[Bash-url]: https://www.gnu.org/software/bash/
[S3-shield]: https://img.shields.io/badge/S3%20Compatible%20Storage-569A31?logo=amazons3&logoColor=fff&style=for-the-badge
[S3-url]: https://aws.amazon.com/s3/
