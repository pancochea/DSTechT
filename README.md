## Pre-installation Considerations

### Requirements:
- Docker
- k0s
- Helm
- kubectl
- A minimum of 16GB of RAM and 8 cores is required for the application to run smoothly.

### Assumptions and Caveats:
- The system must be Unix-based.
- The air gapped installation works only on the amd64 architecture. Due to time constraints, only packages for amd64 were downloaded. If you have a different architecture, you can still perform the installation online.
- The air gapped installation is partial. Due to the size of the containers, only some are stored in the local registry. A list of these containers is included in the air gapped installation documentation.
- The default folder for resources is `/opt/deepset`. To change this, set the `DEEPSET_BASE_PATH` environment variable before running any script.
- The distribution service listens on port 5000. Ensure this port is available.

### Known Issues:
- Uploading a file triggers a long-running process, often resulting in a timeout. The process appears to connect to OpenSearch but then disconnects unexpectedly. Logs indicate that indexing continues in the background.

## Air gapped Installation

As explained throughout this document, the approach to installing all components is designed with an air gapped environment in mind. The goal is to build a package containing all required resources, allowing you to transfer the package to the air gapped system and install everything without requiring an internet connection.

- **Binaries:** Binaries were downloaded using `apt download` and then installed with `dpkg`. The provided packages are for amd64 architectures, but downloading them for other architectures is straightforward.
- **Charts:** Helm charts were downloaded using `helm pull $CHART`, after which they can be referenced locally as usual.
- **Containers:** This is the most labor-intensive part, as you need to retrieve the container registry and version, download the image, re-tag it, and upload it to the local registry. Containers are typically large, causing storage to grow rapidly. In this implementation, only a few containers have been downloaded to demonstrate the process.I created a script to achieve this inthe `scripts` folder.

## Non air gapped Installation

If you want to run the online installation, but still want to use the local registry, run the following commands to start the distribution registry:

```
docker compose -f scripts/docker-compose-registry.yaml up -d
```

Then run the online system build script.

## Air gapped Resources Download

To download all resources for an air gapped installation and avoid rebuilding the `haystack-rag` containers, download the resources file from the link in the mail, and place it in the `resources` folder at the root of this repository (see folder structure section).

## Haystack-rag-ui Containers

It is recommended to use the preloaded containers in the local registry (the resources pack in the link) since some take a long time to build (the indexing container is 6GB). The frontend was built with the argument `--build-arg REACT_APP_HAYSTACK_API_URL=app.deepset.local`, so if you change this URL, the frontend container must be rebuilt.

If you want to use your own registry, change the registry value of the `charts/values/haystack.yaml` values file.

## Haystack-rag-ui Chart

This Helm chart installs all necessary components for `haystack-rag-ui`. Resources are structured as follows:

- **OpenSearch Chart:** A production-ready chart.
- **Backend and Frontend Resources:**
  - `backend/` contains resources common to both backend components, a secret to store the opensearch password and a configmap.
  - `query/` and `index/` contain resources specific to those services.
  - `frontend/`contains all resources related to the react app.
- **Ingress:** A single Ingress resource handles all routes to the backend, simplifying configuration.
- **ServiceMonitor:** Enables Prometheus to scrape metrics. If the `ServiceMonitor` CRD is not installed, this object is skipped.

You can use external secrets to replace the secret common object.

## Folder Structure

```
DEEPSET_BASE_PATH
|- resources
|   |- bin -> Binaries for system installation
|   +- registry_data -> Local registry Docker images
|
|- charts
|   |- manifests -> Extra manifests to apply post-installation. If a file exists with the same name as the installation, it is executed.
|   |- values -> Configuration values for Helm. If a file exists with the same name as the installation, it is included in the Helm command.
|   |- charts -> Helm charts to install. These are small and are directly installed as part of the air gapped installation.
|   +- src -> Source code for `haystack-rag`
|
+- scripts
    |- installation -> Scripts for installing the application
    +- utils -> Other tools and common functions for the installation scripts
```

## Installation Scripts

Inside the `installation` folder, you will find all the Bash scripts required to deploy the `haystack-rag-ui` application on a Kubernetes cluster with monitoring. These scripts must be executed in sequential order, starting with file `0`. While each step can be re-run, they should not be executed out of order.

Ensure the scripts have execution permissions.

### 0 - System Setup
This script installs all necessary tools. If performing an air gapped installation, all binaries must be in the `resources/bin` folder. Installed components:

- **Distribution:** A lightweight local Docker registry. The air gapped installation loads the registry data from `resources/registry_data`. The registry listens on port 5000.
- **Docker:** All required `dpkg` packages and dependencies are stored in `resources/bin`. The `docker` system group is assumed to exist, and the current user is added to it after installation.
- **kubectl**
- **Helm**
- **k0s:** The Kubernetes distribution used to manage containers. The air gapped installation pulls images from the local registry as defined in `k0s.yaml`. 

The script is idempotent and can be re-run as needed.

### 1 - Cluster Base Setup
This script installs all required components for a functional cluster. Re-running it updates the installed charts. Installed components:

- **OpenEBS:** Enables local persistent volume storage.
- **MetalLB:** Provides external access to the cluster. **IMPORTANT:** You must manually configure your local IP in the MetalLB manifest (`charts/manifests`). Failure to do so will cause an error.
- **Ingress Nginx:** Manages Layer 7 requests.

### 2 - Observability (Optional)
Installs the observability stack, which includes Grafana, Prometheus, Loki, and Alloy. Datasources are configured during installation.

### 3 - Secrets management
This script installs Hashicorp vault, initializes it and gets the root keys. This keys are injected into a secrets manifesta that is used later for external-secrets, which is installed next.

There's a problem starting Vault, and external secrets can't use the key to connect to Vault. I was not able to solve the issue on time, so this part is not working.

### 4 - Application Installation
Installs `haystack-rag-ui`:

1. The Helm chart is linted to check for errors, if linting fails, the process is stoped.
2. The package is created.
3. The application is installed using `charts/values/haystack.yaml`.

**IMPORTANT:** The indexing backend container is large (6GB). The first installation attempt may fail. If this happens, re-run the script to complete the process.

## Using the Application

Since requests are routed via an L7 ingress, the `Host` header must be set. The default hostnames are:

- `grafana.deepset.local`
- `app.deepset.local` **(IMPORTANT: If you change this value, the frontend container must be rebuilt to update `REACT_APP_HAYSTACK_API_URL`).**

Add these entries to your hosts file:

- Unix: `/etc/hosts`
- Windows: `C:\\Windows\\System32\\drivers\\etc\\hosts` (requires administrative rights)

Point them to the IP configured in MetalLB.

## Bonus points

### air gapped Installation

air gapped installation requires an ongoing process of resource updates, cleanup, and verification. Also this installations use to be complex, and need to be very stable and secure. All these issues make air gapped environments complex. These environments are usually a result of strict security compliances.

### Observability

Observability is a key part of modern infrasturcture, it helps detect and debug problems faster. But as the log and metrics volume scales, you face differnt problems that usually require splitting the observability infrastructre, for this, prometheus has thanos and loki offers a distributed architecture. The drawback is that this infrastructure requires it's own knowledge and operations, so it's cost increases very fast, both economically and in engineering time. 

Also, having well defined dashboards and alerts it's a contionus work that requires colaboration between teams to know which metrics are more representative or important and avoid noise that can shadow real problems.

### Secrets management

Kuberentes secrets are base64 encoded, so they are not really secure if an unanthorized user hain access to the cluster. To solve this, you use tools like external-secrets, that pull secrets from secure providers. This usually provides enough balance between complexity and security but in high-security environments, secret rotation can automated, ensuring that no individual knows the actual secret values. While this significantly improves security, it requires additional configuration and integration effort, adding complexity to the system.
