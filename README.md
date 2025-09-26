# Immich one-click deployments

This project includes the packer files necessary for one-click depolyments across Marketplace platforms.

### DigitalOcean

[![DigitalOcean Immich one-click button](https://private-user-images.githubusercontent.com/27055614/486883301-096b2035-9a3f-4288-9302-13cbd1d720b9.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTg2NjMwODIsIm5iZiI6MTc1ODY2Mjc4MiwicGF0aCI6Ii8yNzA1NTYxNC80ODY4ODMzMDEtMDk2YjIwMzUtOWEzZi00Mjg4LTkzMDItMTNjYmQxZDcyMGI5LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA5MjMlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwOTIzVDIxMjYyMlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWE1YWI0YzJhMzA3MTllYjVkNWQ5NmY5MzEwZjJjYmJkZDgzYmM0ZTIxYmZjNjI2M2I0YTA5ZmEzNjFlZTI5NjgmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.YCKW56YjrH6nu0PAQQetVMM2GUfaVhL6oLR54OLKO78)](https://marketplace.digitalocean.com/apps/immich?refcode=6bae8242989b&action=deploy)


# Immich First-Time Setup Instructions

## Initial Deployment

Upon deployment, Immich requires several minutes to fully initialize all services. Please allow adequate time for the complete startup process before attempting to access the application.

## Accessing Your Immich Instance

Once the initialization process is complete, access your Immich instance using your server's IP address:

***https://your\_droplet\_public\_ipv4***

Click `Allow` / `Continue` on any security warning while accessing Immich via the IP Address (Follow the Certificate Configuration steps below to avoid this warning.)

## System Architecture

Immich is deployed as Docker containers running under the dedicated `immich` system user. To perform administrative tasks, [login](<https://docs.digitalocean.com/products/droplets/how-to/connect-with-ssh/>) and switch to this user account:

***ssh root@your\_droplet\_public\_ipv4***

```bash
su - immich
```

## Configuration Management

### Application Directory

The Immich application files are located in the following directory:

```bash
cd /home/immich/immich-app/
```

### Environment Configuration

Application settings can be modified through the environment configuration file:

```bash
nano /home/immich/immich-app/.env
```

### Applying Configuration Changes

After making changes to the configuration, restart the Immich services to apply the modifications:

```bash
cd /home/immich/immich-app/ ;
docker-compose down ;
docker-compose up -d
```

### Process Management Scripts

Additional system scripts and utilities for Immich management are located in:

```
/opt/immich/
```

## SSL/TLS Certificate Configuration

### Automatic Certificate Provisioning

When pointing a domain name to your server's IP address, Caddy will automatically provision and configure SSL certificates through Let's Encrypt.

To enable automatic certificate management:

1. Configure your domain's DNS records to point to your server's IP address
2. Access your Immich instance using your domain:

```
https://yourdomain.com/
```

The certificate provisioning process will complete automatically upon first access, refresh the page if this takes more than 60 seconds.

