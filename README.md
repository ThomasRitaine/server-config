<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/ThomasRitaine/server-config">
    <img src="docs/image/logo.webp" alt="Logo" width="175" height="175">
  </a>

<h3 align="center">Server Config</h3>

  <p align="center">
    A containerized server setup with advanced security and backup features for personal production use.
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
        <li><a href="#creating-http-basic-auth-middleware">Creating HTTP Basic Auth Middleware</a></li>
        <li><a href="#configuring-the-backup-system">Configuring the Backup System</a></li>
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

[![File List in terminal][file-list-screenshot]](https://thomas.ritaine.com)

A containerized server setup with advanced security and backup features for personal production use:

- **Dockerized Applications**: Each application runs in its own Docker container, ensuring isolation and ease of management.
- **Advanced Security**: Incorporates SSH key-based logins, TOTP for two-factor authentication, and Fail2Ban for comprehensive server protection.
- **Automated Backups**: Scheduled backup script to archive and secure designated Docker volumes to cloud storage.
- **Personal Production Ready**: Designed to deploy and maintain personal web applications securely and efficiently behind Traefik reverse proxy. Automatic HTTPS, configurable HTTP Basic Auth, auto create subdomains and more.
- **Documentation-Driven**: Detailed installation and setup guides to streamline the server configuration process.
<!-- - **Monitoring and Management**: Integrated monitoring tools like Netdata within Docker, providing insights into server performance. -->

This setup is tailored for developers looking for a secure and maintainable server environment for their personal projects.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

The server configuration leverages a variety of technologies for security, orchestration, and automation:

- [![Docker][Docker-shield]][Docker-url]
- [![Traefik][Traefik-shield]][Traefik-url]
- [![Let's Encrypt][LetsEncrypt-shield]][LetsEncrypt-url]
- [![Bash][Bash-shield]][Bash-url]
- [![Amazon S3][S3-shield]][S3-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

This project contains all the necessary configurations to set up a secure, containerized server environment for personal production use. The setup involves a series of steps that are detailed in two documents.

### Prerequisites

- A fresh VPS with root access
- Basic knowledge of Docker, Linux commands, and server security concepts

### Server Setup

1. **Initial Server Setup**: Follow the steps in `docs/server-setup.md` to prepare your server with the necessary security configurations and user setup.
2. **Dependencies Installation**: Detailed instructions for installing Docker, setting up firewalls, and other dependencies are provided in the same document.

### Project Installation

Once the server is ready, proceed with the installation of this repository by following the steps in `docs/install.md`. This includes cloning the repository, setting up environment variables, and deploying services via Docker.

For full installation instructions, please refer to the documentation:

- [Server Setup Guide](docs/server-setup.md)
- [Installation Guide](docs/install.md)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Environment Variables

For that setup to work properly, you will need to set several environment variables. These variables should be set in a `.env` file that you create based on the provided `.env.example` file. Here is a list of the required environment variables and their descriptions:

| Variable Name    | Description                                             | Example Value                        |
| ---------------- | ------------------------------------------------------- | ------------------------------------ |
| `DOMAIN_NAME`    | The domain name where your services will be hosted.     | `example.com`                        |
| `S3_BUCKET_NAME` | The name of the S3 bucket used for backups.             | `my-backup-bucket`                   |
| `S3_ENDPOINT`    | The endpoint URL for the S3-compatible storage service. | `https://s3.eu-west-2.wasabisys.com` |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->

## Usage

Once your server configuration is set up, deploying applications and managing the server is straightforward.

### Deploying Apps with Docker Behind Traefik

To deploy applications behind Traefik, modify the app's Docker Compose file to include the Traefik network and labels. Here's a simplified example:

```yaml
version: "3.8"

services:
  webapp:
    image: nginx
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`webapp.${DOMAIN_NAME}`)"

networks:
  default:
    external:
      name: proxy
```

Replace `webapp` and `nginx` with your application's service name and image, and update the `DOMAIN_NAME` variable accordingly.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Creating HTTP Basic Auth Middleware

To protect your applications with HTTP Basic Auth:

1. Generate a `.htpasswd` file with your desired username and password, placing it in the `traefik/auth-http-users/` directory.
2. Define the middleware in `traefik/config/middleware.yml` like so:

```yaml
http:
  middlewares:
    auth-http-scope:
      basicAuth:
        usersFile: /auth-http-users/fileName.htpasswd
```

Replace `fileName.htpasswd` by the actual file name.\
Also, replace `auth-http-scope` with the scope you want, `auth-http-admin` for example. Then use it as so in the `docker-compose.yml` of the desired app:

```yaml
services:
  webapp:
    image: nginx
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`webapp.${DOMAIN_NAME}`)"
      - "traefik.http.routers.webapp.middlewares=auth-http-scope@file"
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Configuring the Backup System

To set up backups for your applications:

1. Create a `.backup` file within your application's directory.
2. List the Docker volumes you want to backup, one per line, or use an asterisk `*` to backup all volumes.
3. The backup script will handle the creation and storage of archives according to this configuration.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- FOLDER STRUCTURE AND EXPLANATIONS -->

## Folder Structure

Below is an overview of the key directories and files in this server configuration project:

```
.
├── .github/                  # GitHub-specific configurations and resources.
│   └── ISSUE_TEMPLATE/       # Templates for bug reports and feature requests.
├── backup/                   # Backup scripts and logs.
│   ├── logs/                 # Directory in which backup script logs are written.
│   └── cron_backup.sh        # The backup script.
├── dbeaver/                  # Dbeaver docker setup for database management.
├── docs/                     # Project documentation and resources.
│   └── image/                # Images used to illustrate the documentation.
├── monitoring/               # Monitoring configuration files and docker compose.
│   └── config/               # YML configuration files of the monitoring tools.
├── traefik/                  # Traefik reverse proxy configuration.
│   ├── auth-http-users/      # HTTP Basic Auth users and passwords.
│   ├── certificates/         # SSL Let's Encrypt certificates for HTTPS.
│   ├── config/               # Dynamic configuration.
│   │   ├── https.yml         # SSL layer and HSTS config.
│   │   └── middlewares.yml   # HTTP Basic Auth and IP whitelist config.
│   ├── docker-compose.yml    # Docker Compose file to set up Traefik.
│   └── traefik.yml           # Static configuration.
├── .env                      # Your personal environment variables, do not commit
├── .env.example              # Example environment variables setup.
├── .gitignore                # Specifies files to be ignored by Git.
└── README.md                 # High level project documentation.
```

This structure provides a clear and organized view of the various components of the server setup, from the reverse proxy to monitoring and backup systems.

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

Thomas Ritaine - [@ai_art_tv](https://twitter.com/ai_art_tv) - thomas@ritaine.com

Project Link: [https://github.com/ThomasRitaine/server-config](https://github.com/ThomasRitaine/server-config)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

Special thanks to the following resources and tools that have played a significant role in the development of this server configuration:

- [#Prox-i](https://www.prox-i.pf/) - A communication agency for whom the initial setup was developed, which inspired continuous improvement and led to the current configuration.
- [Docker](https://www.docker.com/) - For the containerization platform that makes it possible to isolate applications.
- [Traefik](https://traefik.io/) - For the excellent reverse proxy, ease of configuration and automatic SSL setup.
- [Let's Encrypt](https://letsencrypt.org/) - For providing free SSL certificates to secure web communications.

This project wouldn't have been possible without these invaluable resources.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

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
[file-list-screenshot]: docs/image/file_list.webp
[Docker-shield]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[Docker-url]: https://www.docker.com/
[Traefik-shield]: https://img.shields.io/badge/Traefik%20Proxy-24A1C1?logo=traefikproxy&logoColor=fff&style=for-the-badge
[Traefik-url]: https://traefik.io/
[LetsEncrypt-shield]: https://img.shields.io/badge/Let's%20Encrypt-003A70?logo=letsencrypt&logoColor=fff&style=for-the-badge
[LetsEncrypt-url]: https://letsencrypt.org/
[Bash-shield]: https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white
[Bash-url]: https://www.gnu.org/software/bash/
[S3-shield]: https://img.shields.io/badge/Amazon%20S3-569A31?logo=amazons3&logoColor=fff&style=for-the-badge
[S3-url]: https://aws.amazon.com/s3/
