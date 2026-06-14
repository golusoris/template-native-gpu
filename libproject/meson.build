# libproject — the shared core: a versioned, append-only interop ABI plus a
# trivial illustrative "hello core". This is the STRUCTURE you keep; replace the
# interop sections and the hello stub with your project's real data plane.
# Adapted from: Pelorus/libpelorus/meson.build.

libproject_inc = include_directories('include')

libproject_sources = files(
  'src/interop.c',
  'src/hello.c',
  'src/version.c',
)

libproject_headers = files(
  'include/project/project.h',
  'include/project/interop.h',
  'include/project/hello.h',
)

libproject = library(
  'project',
  libproject_sources,
  include_directories: libproject_inc,
  version: meson.project_version(),
  soversion: '0',
  install: true,
  gnu_symbol_visibility: 'default',
)

install_headers(libproject_headers, subdir: 'project')

libproject_dep = declare_dependency(
  link_with: libproject,
  include_directories: libproject_inc,
)

pkg = import('pkgconfig')
# No `subdirs:` — headers install to ${includedir}/project/ and are included as
# <project/interop.h>, so the cflags must point at ${includedir} itself.
pkg.generate(
  libproject,
  name: 'libproject',
  description: 'PROJECT native core: versioned side-data interop ABI + a hello stub',
  version: meson.project_version(),
)

if get_option('tests')
  subdir('test')
endif

if get_option('shaders')
  subdir('shaders')
endif
