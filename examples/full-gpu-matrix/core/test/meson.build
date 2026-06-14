# Example test + fuzz harness. The runtime test exercises the backend-agnostic
# dispatch parser, the env snapshot, and the picture pool — none of which need a
# GPU, so this runs green on a stock CI runner.

dispatch_test = executable(
  'gpu_dispatch_test',
  files('test_gpu_dispatch.c'),
  dependencies: libproject_gpu_dep,
)
test('gpu-dispatch', dispatch_test, suite: 'fast')

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
endif
