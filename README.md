# mycloud

This repo contains the config files for apps I self-host for personal use.

Everything is deployed in docker containers, and docker-compose is used to manage the containers. Each service has a template for environment variables in the _templates folder that matches the name of the service as listed in docker-compose.tmpl.yaml.

Secrets are retrieved from AWS Parameter Store and templates are rendered at deploy time using [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html).
