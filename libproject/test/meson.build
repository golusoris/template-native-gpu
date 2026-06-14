# libproject unit + conformance tests.
# Adapted from: Pelorus/libpelorus/test/meson.build.

interop_test = executable(
  'project_interop_test',
  files('interop_test.c'),
  dependencies: libproject_dep,
)

# The shared ABI conformance fixture — any other repo that vendors interop.c
# runs the same checks, so an N+1-minor blob stays parseable by an N-minor
# consumer. See docs/adr/0002-interop-sidedata-abi.md.
test('interop-abi', interop_test, suite: 'fast')
