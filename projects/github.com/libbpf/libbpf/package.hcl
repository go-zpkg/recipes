# github.com/libbpf/libbpf — libbpf, the library that loads and manages BPF
# programs, and the headers the BPF programs themselves include. Step of
# go-zpkg/recipes#348 (design go-zpkg/packages#440): systemd's `bpf-framework`
# option (meson.build:1065-1074 `dependency('libbpf')`) builds its BPF programs
# with it, next to clang (llvm.org) and bpftool (github.com/libbpf/bpftool).
#
# ⛔ WRITTEN FROM libbpf's OWN src/Makefile and LICENSE, at 1.8.0 — the newest
# release (github.com/libbpf/libbpf/releases/latest: v1.8.0, 2026-10-05), the
# same version libbpf/bpftool 7.8.1 carries as its submodule.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in libbpf's own files.
#
# HOW IT BUILDS (src/Makefile, no configure step):
#   PREFIX (:100) defaults /usr and LIBDIR (:101) to $(PREFIX)/lib64 on a 64-bit
#       host (:86-91): both are pinned, LIBDIR to lib, so the libbpf.pc (:125)
#       and the rpath agree.
#   libelf and zlib are found by pkg-config (:51-52), so PKG_CONFIG_PATH names
#       the elfutils and zlib recipes; without pkg-config it would link -lelf -lz
#       from the host (:49).
#   `install` (:160) installs the static and shared libraries, the headers
#       (:73-76, including bpf_helpers.h that BPF programs include) and
#       libbpf.pc. The three kernel UAPI headers linux/{bpf,bpf_common,btf}.h
#       (:77-78) are NOT in `install` ("can be installed by a different
#       package", :166): `install_uapi_headers` (:168) is run here because
#       systemd's BPF programs include <linux/bpf.h> and reach libbpf's include
#       directory with -idirafter (src/bpf/meson.build:213).
#   CFLAGS is left to the Makefile's own default (:38, which carries -Werror).

summary = "libbpf: library to load BPF programs, and the headers BPF programs include"

# LICENSE (the file, one line): "LGPL-2.1-only OR BSD-2-Clause".
license = "LGPL-2.1-only OR BSD-2-Clause"

platforms = ["linux"]

versions {
  # Tags are `v1.8.0`.
  github = "libbpf/libbpf"
}

dependencies = {
  "sourceware.org/elfutils" = "*"
  "zlib.net"                = "1"
}

distributable {
  # The GitHub tag archive: the project publishes no signed tarball.
  url              = "https://github.com/libbpf/libbpf/archive/refs/tags/v{{version.raw}}.tar.gz"
  strip-components = 1

  # 1.8.0: `shasum -a 256` of the downloaded archive; see provenance.note for
  # why this is a cross-check and not a signature.
  sha256 = {
    "1.8.0" = "b7a1e685f90f6a63ead0dd85d053694b222975da8d09c1a966041cff6f0055ff"
  }
}

build {
  dependencies = {
    "gnu.org/make"               = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    PKG_CONFIG_PATH = "{{deps.sourceware.org/elfutils.prefix}}/lib/pkgconfig:{{deps.zlib.net.prefix}}/lib/pkgconfig"
    # src/Makefile:43 appends LDFLAGS to the link of libbpf.so (:119-123).
    LDFLAGS = "-Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/elfutils.prefix}}/lib -Wl,-rpath,{{deps.zlib.net.prefix}}/lib"
  }

  script = [
    "make -C src PREFIX={{prefix}} LIBDIR={{prefix}}/lib --jobs {{ hw.concurrency }}",
    "make -C src PREFIX={{prefix}} LIBDIR={{prefix}}/lib install install_uapi_headers",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/include/bpf/libbpf.h\"",
    "test -f \"{{prefix}}/include/bpf/bpf_helpers.h\"",
    "test -f \"{{prefix}}/include/linux/bpf.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libbpf.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/libbpf.pc\"",
    "test -e \"{{prefix}}/lib/libbpf.so\"",
  ]
}

provenance {
  read = [
    "src/Makefile",  # :11-19 version and map check; :27-53 CC, CFLAGS, pkg-config; :58-78 objects, headers; :86-103 LIBSUBDIR, PREFIX, LIBDIR; :160-172 install targets
    "LICENSE",       # :1 LGPL-2.1-only OR BSD-2-Clause
    "https://github.com/libbpf/libbpf/releases/latest (v1.8.0)",
  ]

  consulted = []

  note = <<EOT
  source     https://github.com/libbpf/libbpf/archive/refs/tags/v1.8.0.tar.gz
  sha256     b7a1e685f90f6a63ead0dd85d053694b222975da8d09c1a966041cff6f0055ff

⚠ NO SIGNATURE. The project publishes no detached signature that was checked;
the digest is the one this recipe's author computed on the GitHub tag archive,
not a project-published checksum. GitHub regenerates tag archives from the
tag's commit, so a digest mismatch means a changed archive or a moved tag, to
be investigated and not re-pinned blindly.

⛔ NOT BUILT. Unverified: that elfutils installs libelf.pc under lib (and not
lib64) in this tree; that -Werror (the Makefile's own default CFLAGS) holds
with this tree's gcc; that LDFLAGS reaches the shared link as src/Makefile:43
says (read, not run).
EOT
}
