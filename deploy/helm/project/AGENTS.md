# deploy/helm/project — agent guide

An app-agnostic chart. The workload kind is chosen by `values.kind`
(Deployment | StatefulSet | Job) and rendered from one shared pod spec
(`_helpers.tpl` → `project.podSpec`).

- **GPU affinity** is derived from `gpu.vendor` → the resource key
  (`nvidia.com/gpu` / `amd.com/gpu` / `gpu.intel.com/i915`) and added to both
  the container resource limits and a `requiredDuringScheduling` node affinity.
- **Hardened by default**: rootless (`runAsNonRoot`, UID 65532), read-only root
  FS, dropped capabilities, `seccompProfile: RuntimeDefault`. A read-only root FS
  needs the `scratch` emptyDir for temp work.
- `values.schema.json` validates input — keep it in sync when adding a value.
- Lint before committing: `helm lint deploy/helm/project` and
  `helm template deploy/helm/project | kubectl apply --dry-run=client -f -`.
