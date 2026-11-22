# github.com/libbpf/bpftool — bpftool, the BPF inspection and skeleton
# generator. Step of go-zpkg/recipes#348 (design go-zpkg/packages#440):
# systemd's `bpf-framework` option runs `bpftool gen object` and `bpftool gen
# skeleton` on the BPF programs clang compiled (src/bpf/meson.build:48-62,
# :220-243); it needs bpftool >= 5.13.0 for the first (:51).
#
# ⛔ SOURCE: github.com/libbpf/bpftool, not the kernel tree. Its README says
# "This is the official home for bpftool. Please use this Github repository for
# building and packaging bpftool", while the AUTHORITATIVE source is developed
# in the bpf-next tree under tools/bpf/bpftool and synced here. Read at 7.8.1,
# the newest release (releases/latest: v7.8.1, 2026-10-20).
# The asset `bpftool-libbpf-v<ver>-sources.tar.gz` ("Source code, including
# libbpf submodule") is used, NOT the GitHub tag archive: that one leaves the
# libbpf submodule empty (README: "This repository uses libbpf as a
# submodule"). It carries libbpf 1.8.0, built into bpftool as a static
# archive, so no libbpf recipe is a dependency.
#
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# OPTIONS (src/Makefile):
#   SKIP_LLVM=1, SKIP_LIBBFD=1 (:113-117, :175-219): JIT-disassembly support
#       comes from LLVM or from binutils' libbfd, whichever the build host
#       carries (a host probe, :127-131). Neither has a declared link path
#       here: OFF, so the host's cannot enter. `bpftool prog dump jited` is
#       then unavailable.
#   SKIP_CRYPTO stays unset: program signing (:118-120) links libcrypto, taken
#       from the openssl.org recipe.
#   VMLINUX_BTF= (:239-251): left alone it falls back to /sys/kernel/btf/vmlinux
#       of the BUILD host and, if clang is found, builds the profiler and
#       pid_iter skeletons from it (:248-280). Given empty on the command line it
#       is empty, so nothing is built from the host's kernel and
#       -DBPFTOOL_WITHOUT_SKELETONS is set (:282): `bpftool prog profile` and
#       the PIDs shown for BPF objects are unavailable.
#   libcap (:128, :164-167) and libelf's zstd (:134, :159-162) are host probes
#       too: both are declared dependencies, with their include and link paths.
#   The install is `install-bin` (:312-315): {prefix}/sbin/bpftool. `install`
#       (:317) would also write bash completion into the absolute path
#       /usr/share/bash-completion/completions (:70) — a write outside the
#       prefix.

summary = "bpftool: inspect and manipulate BPF programs and maps, generate BPF skeletons"

# LICENSE (the file, one line): "GPL-2.0-only OR BSD-2-Clause".
license = "GPL-2.0-only OR BSD-2-Clause"

platforms = ["linux"]

versions {
  # Tags are `v7.8.1`.
  github = "libbpf/bpftool"
}

dependencies = {
  "sourceware.org/elfutils" = "*"
  "zlib.net"                = "1"
  "openssl.org"             = "^3"
  "facebook.com/zstd"       = "1"
  "kernel.org/libcap"       = "^2"
}

distributable {
  # The release asset with the libbpf submodule; the project publishes no
  # detached signature that was checked.
  url              = "https://github.com/libbpf/bpftool/releases/download/v{{version.raw}}/bpftool-libbpf-v{{version.raw}}-sources.tar.gz"
  strip-components = 1

  # 7.8.1: 1594958 bytes. `shasum -a 256` of the downloaded asset gave the
  # digest below, which is also the `digest` the GitHub release API states for
  # the asset (two answers from GitHub, not an independent source); see
  # provenance.note.
  sha256 = {
    "7.8.1" = "fed76b7acb54d810cc3982eb6394726010114977542fd146695887a7d904b60c"
  }
}

build {
  dependencies = {
    "gnu.org/make"               = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    # libbpf's own Makefile (built from the submodule) finds libelf and zlib by
    # pkg-config; bpftool's src/Makefile:156 links -lelf -lz -lcrypto directly,
    # so the include and link paths follow.
    PKG_CONFIG_PATH = "{{deps.sourceware.org/elfutils.prefix}}/lib/pkgconfig:{{deps.zlib.net.prefix}}/lib/pkgconfig"
    EXTRA_CFLAGS    = "-I{{deps.sourceware.org/elfutils.prefix}}/include -I{{deps.zlib.net.prefix}}/include -I{{deps.openssl.org.prefix}}/include -I{{deps.facebook.com/zstd.prefix}}/include -I{{deps.kernel.org/libcap.prefix}}/include"
    LDFLAGS         = "-L{{deps.sourceware.org/elfutils.prefix}}/lib -L{{deps.zlib.net.prefix}}/lib -L{{deps.openssl.org.prefix}}/lib -L{{deps.facebook.com/zstd.prefix}}/lib -L{{deps.kernel.org/libcap.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/elfutils.prefix}}/lib -Wl,-rpath,{{deps.zlib.net.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib -Wl,-rpath,{{deps.facebook.com/zstd.prefix}}/lib -Wl,-rpath,{{deps.kernel.org/libcap.prefix}}/lib"
  }

  script = [
    "make -C src SKIP_LLVM=1 SKIP_LIBBFD=1 VMLINUX_BTF= --jobs {{ hw.concurrency }}",
    "make -C src SKIP_LLVM=1 SKIP_LIBBFD=1 VMLINUX_BTF= prefix={{prefix}} install-bin",
  ]
}

# src/Makefile:314-315 installs sbin/bpftool.
provides = [
  "sbin/bpftool",
]

test {
  script = [
    "test -x \"{{prefix}}/sbin/bpftool\"",
    "\"{{prefix}}/sbin/bpftool\" --version >/dev/null",
  ]
}

provenance {
  read = [
    "README.md",   # :18-31 official home and authoritative source; :54-74 dependencies; :79-90 libbpf submodule
    "src/Makefile", # :8 version; :69 prefix; :80-85 CFLAGS; :111-167 SKIP_*, feature probes, LIBS; :239-282 VMLINUX_BTF and skeletons; :312-317 install
    "LICENSE",     # :1 GPL-2.0-only OR BSD-2-Clause
    "https://api.github.com/repos/libbpf/bpftool/releases/latest (v7.8.1, its assets and release notes)",
  ]

  consulted = []

  note = <<EOT
  source     https://github.com/libbpf/bpftool/releases/download/v7.8.1/bpftool-libbpf-v7.8.1-sources.tar.gz
  sha256     fed76b7acb54d810cc3982eb6394726010114977542fd146695887a7d904b60c

⚠ NO SIGNATURE. The project publishes no detached signature that was checked.
The digest was computed on the downloaded asset and equals the `digest` field
the GitHub release API gives for it: both come from GitHub, so this is a
transport check, not an independent one.

The authoritative source is the bpf-next tree (tools/bpf/bpftool); this recipe
builds the project's own packaging mirror, as its README directs.

⛔ NOT BUILT. Unverified: that EXTRA_CFLAGS and LDFLAGS from the environment
reach the feature probes of src/Makefile.feature (not read), so the libcap and
zstd probes may still depend on the host; that `VMLINUX_BTF=` empty on the
command line disables the skeletons as :248 reads.
EOT
}
