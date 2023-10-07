# Infrastructure

This repository hold everything concerning deployment, scripts and CI/CD.

## Requirements

- Docker
- Docker Compose

## Compose

The root of this repository contains a docker-compose file that can be used to deploy the whole infrastructure. It can be used in development or production.

Copy .env.example to .env and fill the variables.

```bash
cp .env.example .env
```

Then run the following command to start the infrastructure.

```bash
docker-compose up -d
```

## Scripts

The scripts folder contains scripts that can be used to deploy the infrastructure on a server.

The scripts are:

- `keycloak/init-script.sh`: This script is used to initialize the keycloak realm, client, smtp access and smtp user. It also creates an test users for development if the `DEV` environment variable is set to `true`. It is executed when the `keycloak-init` container is started.
- `postgresql/init.sh`: This script is used to initialize the postgresql database. It is executed when the `postgresql` container is started. It creates the keycloak database and user. If you want to add more databases, you can add them here.
