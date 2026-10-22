# deploy/helm/project — agent guide

App-agnostic chart. Workload kind selected via `values.kind`
(Deployment | StatefulSet | Job); rendered from shared pod spec
(`_helpers.tpl` -> `project.podSpec`).

- **GPU affinity**: derived from `gpu.vendor` -> resource key
  (`nvidia.com/gpu` / `amd.com/gpu` / `gpu.intel.com/i915`); added to both
  container resource limits and `requiredDuringScheduling` node affinity.
- **Hardened by default**: rootless (`runAsNonRoot`, UID 65532), read-only root
  FS, dropped capabilities, `seccompProfile: RuntimeDefault`. Read-only root FS
  needs `scratch` emptyDir for temp work.
- `values.schema.json` validates input; keep in sync when adding value.
- Lint before commit: `helm lint deploy/helm/project` and
  `helm template deploy/helm/project | kubectl apply --dry-run=client -f -`.
- CI check: `bash scripts/ci/helm-chart-check.sh` validates schemas, vendor
  GPU resource keys, strict lint.
