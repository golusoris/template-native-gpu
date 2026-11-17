# Example test + fuzz harness. The runtime test exercises the backend-agnostic
# dispatch parser, the env snapshot, and the picture pool — none of which need a
# GPU, so this runs green on a stock CI runner.

dispatch_test = executable(
  'gpu_dispatch_test',
  files('test_gpu_dispatch.c'),
  dependencies: libproject_gpu_dep,
)
test('gpu-dispatch', dispatch_test, suite: 'fast')

# The enabled backend already defines the selector in its SYCL object.
if not is_sycl_enabled
  sycl_dispatch_test = executable(
    'sycl_dispatch_strategy_test',
    files('test_sycl_dispatch_strategy.c', '../src/sycl/dispatch_strategy.cpp'),
    dependencies: libproject_gpu_dep,
  )
  test('sycl-dispatch-strategy', sycl_dispatch_test, suite: 'fast')
endif

# Fuzz target — built only when the compiler accepts -fsanitize=fuzzer (clang).
# CI wires this into the `fuzz` workflow; locally:
#   meson setup build -Db_sanitize=address && meson compile -C build
if cc.has_argument('-fsanitize=fuzzer')
  fuzz_parse = executable(
    'fuzz_dispatch_parse',
    files('fuzz/fuzz_dispatch_parse.c'),
    c_args: ['-fsanitize=fuzzer,address'],
    link_args: ['-fsanitize=fuzzer,address'],
    include_directories: core_inc,
    build_by_default: false,
  )
else
  # Without libFuzzer the harness still compiles, so the compile database lists it.
  static_library(
    'fuzz_dispatch_parse_lint',
    files('fuzz/fuzz_dispatch_parse.c'),
    include_directories: core_inc,
    install: false,
  )
endif
