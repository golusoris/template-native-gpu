# metal/ — agent guide

Metal (Apple Silicon) backend. Pipeline: `scale_kernel.metal` →
`xcrun metal -c` → `.air` → `xcrun metallib` → `default.metallib`, embedded into
the binary's `__TEXT,__metallib` section via
`-Wl,-sectcreate,__TEXT,__metallib,…`.

- Only compiled on a `darwin` host (the `enable_metal` option is `auto` → on for
  darwin, off everywhere else). Non-darwin builds link `stubs.c` (`-ENOSYS`).
- Real API dispatch lives in `common.m` (Objective-C; `dispatch_strategy.c`
  stays pure C). Use ARC (`-fobjc-arc`) for the `.m`/`.mm` TUs.
- Load the metallib at runtime from the embedded section via the linker-defined
  symbols, not from a file path.
- Dispatch overrides: `PROJ_METAL_DISPATCH=<feature>:indirect`.
