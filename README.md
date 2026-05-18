# Hermes Agent — MicroK8s Deployment

Kubernetes manifests for deploying [Hermes Agent](https://github.com/nousresearch/hermes-agent) on a MicroK8s cluster. This configuration provisions persistent storage, runs the gateway service, and exposes both the API and dashboard via NodePort.

---

## Prerequisites

- MicroK8s with the following add-ons enabled:
  - `storage` (OpenEBS Jiva CSI)
  - `dns`
- Access to pull `nousresearch/hermes-agent:latest` from Docker Hub

Enable required add-ons if not already active:

```bash
microk8s enable dns
microk8s enable community
microk8s enable openebs
```

---

## Resources

| Resource | Kind | Description |
|---|---|---|
| `hermes-pvc` | PersistentVolumeClaim | 5 GiB volume for agent data/cache |
| `hermes-agent` | Deployment | Single-replica gateway deployment |
| `hermes-service` | Service | NodePort service exposing API and dashboard |

---

## Deployment

Apply the manifest:

```bash
microk8s kubectl apply -f hermes.yaml
```

Verify everything is running:

```bash
microk8s kubectl get pods,svc,pvc
```

---

## Configuration

The following environment variables are set on the container. Edit the manifest before applying to customize behavior.

| Variable | Default | Description |
|---|---|---|
| `PYTHONPATH` | `/opt/python-packages` | Path where init container installs extra deps |
| `HERMES_DASHBOARD` | `1` | Enables the web dashboard |
| `API_SERVER_ENABLED` | `true` | Enables the REST API server |
| `API_SERVER_HOST` | `0.0.0.0` | API listen address |
| `API_SERVER_KEY` | `super_secret_key` | **Change this.** API authentication key |
| `OUTPUT_DIR` | `/opt/data/cache/documents` | Directory for document output |

> ⚠️ **Security:** Replace `API_SERVER_KEY` with a strong secret before deploying to any non-local environment. Consider using a Kubernetes Secret instead of a plain env value.

---

## Ports & Access

| Service | Internal Port | NodePort | URL (replace `<node-ip>`) |
|---|---|---|---|
| Gateway API | 8642 | 31642 | `http://<node-ip>:31642` |
| Dashboard | 9119 | 31119 | `http://<node-ip>:31119` |

Find your node IP:

```bash
microk8s kubectl get nodes -o wide
```

---

## Storage

| Volume | Type | Mount Path | Details |
|---|---|---|---|
| `hermes-storage` | PersistentVolumeClaim | `/opt/data` | 5 GiB via `openebs-jiva-csi-default` |
| `dshm` | emptyDir (Memory) | `/dev/shm` | Shared memory, capped at 1 GiB |
| `shared-packages` | emptyDir | `/opt/python-packages` | Populated by init container |


---

## Resource Limits

| | CPU | Memory |
|---|---|---|
| Request | 1.0 core | 2 GiB |
| Limit | 2.0 cores | 4 GiB |

---

## Init Container

Before the main container starts, an init container (`install-deps`) installs `python-telegram-bot` into the shared `/opt/python-packages` volume using `uv pip install`. Add any additional Python dependencies to this step as needed.

---

## Teardown

```bash
# Remove deployment and service (keeps PVC/data)
microk8s kubectl delete -f hermes.yaml

# Also delete persistent data
microk8s kubectl delete pvc hermes-pvc
```
