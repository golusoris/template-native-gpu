# =============================================================================
# Full GPU-matrix example — multi-backend compute dispatch scaffolding.
#
# This is the vmafx-shaped variant. It shows the per-backend device-code
# compilation pipelines and the host dispatch wiring for FIVE backends:
#
#   CUDA   : nvcc  -> .fatbin -> bin2c -> embedded C array (PTX/cubin)
#   HIP    : hipcc --genco -> .hsaco -> xxd -i -> embedded C array
#   Metal  : xcrun metal -> .air -> xcrun metallib -> default.metallib
#            (embedded via -Wl,-sectcreate,__TEXT,__metallib,…)
#   SYCL   : icpx -fsycl -> per-TU .o, with the LOAD-BEARING -fsycl link-arg
#            propagated through declare_dependency(link_args:['-fsycl'])
#   Vulkan : glslangValidator -V -> .spv
#
# Every backend is OFF/auto by default and ships a `stubs.c` whose entry points
# return -ENOSYS, so this configures + compiles on a stock runner with no GPU
# SDK installed. Run from this dir:  `meson setup build && meson compile -C build`.
#
# TEMPLATE: the kernels are illustrative stubs (a trivial "scale" kernel per
# backend). Replace the kernel sources + the dispatch bodies with your real
# compute. Keep the build wiring and the dispatch pattern.
# Adapted from: vmaf/core/src/meson.build (the load-bearing custom_target +
# declare_dependency patterns), vmaf/core/src/{hip,metal}/meson.build.
# =============================================================================
project(
  'project-gpu-matrix',
  ['c', 'cpp'],
  version: '0.1.0',
  license: 'EUPL-1.2',
  default_options: [
    'c_std=c11',
    'cpp_std=c++20',
    'warning_level=3',
    'default_library=shared',
  ],
  meson_version: '>=0.63.0',
)

cc = meson.get_compiler('c')
fs = import('fs')

is_cuda_enabled  = get_option('enable_cuda')
is_sycl_enabled  = get_option('enable_sycl')
is_hip_enabled   = get_option('enable_hip')
is_vulkan_enabled = get_option('enable_vulkan')

metal_opt = get_option('enable_metal')
if metal_opt.auto()
  is_metal_enabled = (host_machine.system() == 'darwin')
else
  is_metal_enabled = metal_opt.enabled()
endif

core_inc = include_directories('src')
core_cflags = ['-DPROJ_GPU_MATRIX']

# Always-compiled, backend-agnostic host glue.
core_host_sources = [
  'src/gpu_dispatch_env.c',
  'src/gpu_picture_pool.c',
]

# Per-backend object sets + dependencies accumulate here, then fold into the
# final library() via the *_objects / *_deps lists.
backend_sources = []          # plain host .c TUs (dispatch + stubs)
backend_objects = []          # custom_target .o sets (e.g. SYCL icpx output)
backend_deps    = []          # declare_dependency() handles (link args, libs)
embedded_device_code = []     # bin2c / xxd / metallib generated sources

# -----------------------------------------------------------------------------
# CUDA — nvcc compiles each .cu to a .fatbin, bin2c embeds it as a C array.
# -----------------------------------------------------------------------------
if is_cuda_enabled
  core_cflags += '-DHAVE_CUDA'
  backend_sources += files(
    'src/cuda/common.c',
    'src/cuda/dispatch_strategy.c',
  )

  cuda_kernels = {
    'scale_kernel' : 'src/cuda/scale_kernel.cu',
  }

  if get_option('enable_nvcc')
    nvcc_exe = find_program('nvcc')
    # Cover consumer generations Turing -> Ada, plus a compute_80 PTX JIT floor.
    gencode = [
      '--fatbin',
      '-gencode=arch=compute_75,code=sm_75',
      '-gencode=arch=compute_80,code=sm_80',
      '-gencode=arch=compute_80,code=compute_80',  # PTX JIT floor for sm_80+
      '-gencode=arch=compute_86,code=sm_86',
      '-gencode=arch=compute_89,code=sm_89',
    ]
    cuda_flags = ['-D_USE_MATH_DEFINES', '--std', 'c++20']

    fatbins = {}
    foreach name, src : cuda_kernels
      t = custom_target('cu_fatbin_' + name,
        build_by_default: true,
        output: name + '.fatbin',
        input: src,
        command: [nvcc_exe, gencode, '@INPUT@', '-o', '@OUTPUT@',
                  '-I', meson.current_source_dir() / 'src',
                  '-DDEVICE_CODE'] + cuda_flags,
      )
      fatbins += {name: [t]}
    endforeach

    # bin2c ships with the CUDA toolkit. `--padd 0x00` NUL-terminates the array.
    bin2c_exe = find_program('bin2c')
    foreach name, fb : fatbins
      embedded_device_code += custom_target('cu_bin2c_' + name,
        build_by_default: true,
        output: name + '.c',
        input: fb,
        capture: true,
        command: [bin2c_exe, '--const', '--padd', '0x00',
                  '--name', name + '_ptx', '@INPUT@'],
      )
    endforeach
  endif

  cuda_lib = cc.find_library('cuda', required: false)
  if cuda_lib.found()
    backend_deps += declare_dependency(dependencies: [cuda_lib])
  endif
else
  backend_sources += files('src/cuda/stubs.c')
endif

# -----------------------------------------------------------------------------
# HIP — hipcc --genco compiles each .hip to a .hsaco, xxd -i embeds it.
# -----------------------------------------------------------------------------
if is_hip_enabled
  core_cflags += '-DHAVE_HIP'
  backend_sources += files(
    'src/hip/common.c',
    'src/hip/dispatch_strategy.c',
  )

  if get_option('enable_hipcc')
    core_cflags += '-DHAVE_HIPCC'
    hipcc_exe = find_program('hipcc')
    xxd_exe   = find_program('xxd')

    # GFX target discovery: explicit option -> rocm_agent_enumerator ->
    # hipconfig -> a multi-target fallback covering common CDNA2/RDNA2/3 parts
    # (so a no-GPU build sandbox still produces a runnable fat binary).
    hip_gfx_raw = get_option('hip_gfx_targets').strip()
    if hip_gfx_raw == ''
      r = run_command('sh', '-c',
        'rocm_agent_enumerator 2>/dev/null | grep -E "^gfx" | tr "\n" "," | sed "s/,$//g" || true',
        check: false)
      hip_gfx_raw = r.stdout().strip()
    endif
    if hip_gfx_raw == ''
      hip_gfx_raw = 'gfx90a,gfx1030,gfx1100'
    endif
    hip_offload_flags = []
    foreach t : hip_gfx_raw.split(',')
      tt = t.strip()
      if tt != ''
        hip_offload_flags += ['--offload-arch=' + tt]
      endif
    endforeach
    message('HIP HSACO targets: ' + ' '.join(hip_offload_flags))

    hip_kernels = {
      'scale_kernel' : 'src/hip/scale_kernel.hip',
    }
    foreach name, src : hip_kernels
      hsaco = custom_target('hip_hsaco_' + name,
        build_by_default: true,
        output: name + '.hsaco',
        input: src,
        command: [hipcc_exe, '--genco'] + hip_offload_flags +
                 ['-I', meson.current_source_dir() / 'src',
                  '@INPUT@', '-o', '@OUTPUT@'],
      )
      embedded_device_code += custom_target('hip_hsaco_c_' + name,
        build_by_default: true,
        output: name + '_hsaco.c',
        input: hsaco,
        capture: true,
        command: [xxd_exe, '-i', '-n', name + '_hsaco', '@INPUT@'],
      )
    endforeach
  endif

  hip_lib = cc.find_library('amdhip64',
    dirs: ['/opt/rocm/lib', '/opt/rocm/lib64'], required: false)
  if hip_lib.found()
    backend_deps += declare_dependency(
      dependencies: [hip_lib],
      compile_args: ['-D__HIP_PLATFORM_AMD__=1'],
    )
  endif
else
  backend_sources += files('src/hip/stubs.c')
endif

# -----------------------------------------------------------------------------
# Metal — xcrun metal -> .air -> xcrun metallib -> default.metallib, embedded
# into the binary's __TEXT,__metallib section via the linker.
# -----------------------------------------------------------------------------
if is_metal_enabled
  core_cflags += '-DHAVE_METAL'
  add_languages('objc', native: false, required: true)

  foundation_dep = dependency('Foundation', required: true)
  metal_dep      = dependency('Metal', required: true)
  backend_deps  += [foundation_dep, metal_dep]

  # dispatch_strategy is pure C; the real Metal dispatch would be .m / .mm.
  backend_sources += files('src/metal/common.m', 'src/metal/dispatch_strategy.c')

  xcrun = find_program('xcrun', required: true)
  scale_air = custom_target('scale_air',
    input: 'src/metal/scale_kernel.metal',
    output: 'scale_kernel.air',
    command: [xcrun, '-sdk', 'macosx', 'metal', '-c', '@INPUT@', '-o', '@OUTPUT@'],
  )
  metallib = custom_target('default-metallib',
    input: [scale_air],
    output: 'default.metallib',
    command: [xcrun, '-sdk', 'macosx', 'metallib', '@INPUT@', '-o', '@OUTPUT@'],
  )
  backend_deps += declare_dependency(
    sources: metallib,
    link_args: ['-Wl,-sectcreate,__TEXT,__metallib,' + metallib.full_path()],
  )
else
  backend_sources += files('src/metal/stubs.c')
endif

# -----------------------------------------------------------------------------
# SYCL — icpx -fsycl compiles each .cpp TU to a .o. The -fsycl link arg MUST be
# present at every link step that pulls in these objects (else the SYCL runtime
# never registers device kernels and the first queue.submit() SIGSEGVs). We
# propagate it via declare_dependency(link_args:['-fsycl']) — the load-bearing
# line of this whole example.
# -----------------------------------------------------------------------------
if is_sycl_enabled
  core_cflags += '-DHAVE_SYCL'

  sycl_compiler_opt = get_option('sycl_compiler')
  icpx = find_program(sycl_compiler_opt, required: true)
  sycl_basename = fs.name(sycl_compiler_opt)
  is_acpp = (sycl_basename == 'acpp' or sycl_basename == 'syclcc' or sycl_basename == 'syclcc-clang')

  if is_acpp
    sycl_toolchain_args = ['--acpp-targets=' + get_option('sycl_acpp_targets')]
  else
    aot = get_option('sycl_icpx_aot_targets')
    if aot != ''
      # AOT: emit native ISA blobs for the listed targets + a SPIR-V fallback.
      sycl_toolchain_args = ['-fsycl', '-fsycl-targets=spir64_gen,spir64',
                             '-Xs', '-device ' + aot]
    else
      # JIT: portable SPIR-V only, compiled to native ISA at first launch.
      sycl_toolchain_args = ['-fsycl']
    endif
  endif

  sycl_inc_flags = [
    '-I' + meson.current_source_dir() / 'src',
    '-I' + meson.current_source_dir() / 'src' / 'sycl',
  ]
  sycl_pic = (host_machine.system() != 'windows') ? ['-fPIC'] : []
  sycl_common_args = core_cflags + ['-c', '-std=c++20'] + sycl_toolchain_args + sycl_pic

  sycl_sources = ['src/sycl/common.cpp', 'src/sycl/dispatch_strategy.cpp']
  foreach src : sycl_sources
    name = fs.stem(src)
    backend_objects += custom_target('sycl_' + name,
      output: name + '.o',
      input: src,
      command: [icpx] + sycl_common_args + sycl_inc_flags + ['@INPUT@', '-o', '@OUTPUT@'],
    )
  endforeach

  # Resolve the SYCL runtime lib dir from the compiler location so a non-Intel
  # host linker (gcc/g++) can find it.
  icpx_bindir = fs.parent(icpx.full_path())
  sycl_lib_dir = fs.parent(icpx_bindir) / 'lib'
  if is_acpp
    sycl_rt = cc.find_library('acpp-rt', dirs: [sycl_lib_dir], required: false)
    if not sycl_rt.found()
      sycl_rt = cc.find_library('hipSYCL-rt', dirs: [sycl_lib_dir], required: true)
    endif
    sycl_extra_rt = []
  else
    sycl_rt = cc.find_library('sycl', dirs: [sycl_lib_dir], required: true)
    # icpx objects reference Intel runtime symbols (__svml_*, _intel_*) gcc/g++
    # won't find; link them explicitly so a non-Intel host linker resolves them.
    sycl_extra_rt = []
    if host_machine.system() != 'windows'
      sycl_extra_rt += cc.find_library('svml', dirs: [sycl_lib_dir], required: false)
      sycl_extra_rt += cc.find_library('irc',  dirs: [sycl_lib_dir], required: false)
    endif
  endif

  # *** THE LOAD-BEARING LINE ***
  # -fsycl must be present at every link step that pulls in SYCL .o files;
  # embedding it here propagates it to libproject_gpu.so AND every test exe that
  # declares this dependency, with no per-target duplication.
  backend_deps += declare_dependency(
    dependencies: [sycl_rt] + sycl_extra_rt,
    link_args: ['-fsycl'],
  )
else
  backend_sources += files('src/sycl/stubs.c')
endif

# -----------------------------------------------------------------------------
# Vulkan — glslangValidator compiles the reference compute shader to SPIR-V.
# -----------------------------------------------------------------------------
if is_vulkan_enabled
  glslang = find_program('glslangValidator', required: false)
  if glslang.found()
    custom_target('scale-spv',
      input: 'src/vulkan/scale.comp',
      output: 'scale.spv',
      command: [glslang, '-V', '--target-env', 'vulkan1.2', '@INPUT@', '-o', '@OUTPUT@'],
      build_by_default: true,
    )
  else
    message('glslangValidator not found — skipping Vulkan reference shader')
  endif
endif

# -----------------------------------------------------------------------------
# The library. Backend objects fold in via objects:, generated device-code C
# arrays via the sources list, and link args / runtime libs via dependencies:.
# -----------------------------------------------------------------------------
libproject_gpu = library(
  'project_gpu',
  core_host_sources + backend_sources + embedded_device_code,
  objects: backend_objects,
  include_directories: core_inc,
  c_args: core_cflags,
  cpp_args: core_cflags,
  # common.m needs HAVE_METAL too, else it compiles to an empty unit.
  objc_args: core_cflags,
  dependencies: backend_deps,
  version: meson.project_version(),
  soversion: '0',
  install: true,
)

libproject_gpu_dep = declare_dependency(
  link_with: libproject_gpu,
  include_directories: core_inc,
  # Re-export backend_deps so test exes inherit -fsycl etc. transitively.
  dependencies: backend_deps,
)

if get_option('enable_tests')
  subdir('test')
endif
