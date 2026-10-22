# metal/ — agent guide

Metal (Apple Silicon) backend. Pipeline: `scale_kernel.metal` ->
`xcrun metal -c` -> `.air` -> `xcrun metallib` -> `default.metallib`, embedded into
binary `__TEXT,__metallib` section via
`-Wl,-sectcreate,__TEXT,__metallib,…`.

- Only compiled on `darwin` host (`enable_metal` option = `auto` -> on for
  darwin, off elsewhere). Non-darwin builds link `stubs.c` (`-ENOSYS`).
- Real API dispatch lives in `common.m` (Objective-C; `dispatch_strategy.c`
  stays pure C). Use ARC (`-fobjc-arc`) for `.m`/`.mm` TUs.
- Load metallib at runtime from embedded section via linker-defined
  symbols, not file path.
- Dispatch overrides: `PROJ_METAL_DISPATCH=<feature>:indirect`.
