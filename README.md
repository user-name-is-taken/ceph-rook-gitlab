# Gitlab-rook helm chart

- This repo contains a [bash script](install.sh) that deploys a gitlab instance that uses s3 storage from rook.

## How it works

- The bash script 
- `--set gitlab.enable=false`
- `--no-hooks`
- Resolving rook url from inside container
- helm values 
  - `minio.enabled = false`
  - [global settings](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/charts/globals.md#lfs-artifacts-uploads-packages-and-external-mr-diffs)

- [gitlab is disabled at first](https://stackoverflow.com/questions/54032974/helm-conditionally-install-subchart)

- 2 sections for storage
  1. [running app storage](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/doc/advanced/external-object-storage)
    - [connection section](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/charts/globals.md#connection)
  2. [backup and restore storage](https://docs.gitlab.com/ee/raketasks/backup_restore.html)
    - [more](https://docs.gitlab.com/ee/raketasks/backup_restore.html#other-s3-providers)
    - [s3cfg](https://medium.com/flant-com/to-rook-in-kubernetes-df13465ff553)

### where you can see it working

- `kubectl get ing` shows an ingress rule for gitlab which points to the unicorn service
- use `kubectl get svc` to find the unicorn service's IP address

## Future convert it to fully helm

- [Gitlab issue about it](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1920)

# notes

- [fog library](https://docs.gitlab.com/ee/raketasks/backup_restore.html#other-s3-providers)