# Basic App Module

This basic app module is used to deploy the basic app service located in this repo at /basic-app. Some properties of this example AWS ECS appliction is:

* Service configuration occurs via environment variables stored using AWS Parameter store.
* The service exposes a single port as a service
* The service health check is a simple wget to the the service.

## Deploying the basic app

An example top level terraform configuration for deploying this ECS service can be found in this repo at /tf-deploy/myapp.
