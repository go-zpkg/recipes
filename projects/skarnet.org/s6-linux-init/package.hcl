# skarnet.org/s6-linux-init — a suite to make a Linux system boot with s6 as
# process 1: `s6-linux-init-maker` generates a complete init directory (the
# `init` binary's stage-1 and stage-2 scripts, a shutdown daemon, the
# scan directory skeleton), and s6-linux-init-shutdown, -hpr and -telinit are
# the run-time commands that stop the machine.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 1.2.0.2, the
# newest release on https://skarnet.org/software/s6-linux-init/ (GitHub mirror
# tag v1.2.0.2). Digest computed from the download.
#
# Requirements from INSTALL: skalibs, execline and s6. The optional nsss and
# utmps are left OFF (`--enable-nsss`, `--enable-utmps` default disabled): with
# glibc the libc's own user database and utmp work. Defaults kept: --skeldir
# PREFIX/etc/s6-linux-init/skel, --tmpfsdir /run, --scandir service (so the
# scan directory is /run/service at run time).
#
# Linux only (INSTALL: "This software is Linux-specific"). The generated init
# directory holds absolute paths of execline and s6 binaries, taken from the
# environment s6-linux-init-maker runs in (-p initial_path).

summary = "s6-linux-init: generate and run an s6-based init system for Linux (s6-linux-init-maker, -shutdown, -telinit)"

# COPYING: ISC licence.
license = "ISC"

platforms = ["linux"]

versions {
  github = "skarnet/s6-linux-init"
}

dependencies = {
  "skarnet.org/skalibs"  = "^2"
  "skarnet.org/execline" = "^2"
  "skarnet.org/s6"       = "^2"
}

distributable {
  url              = "https://skarnet.org/software/s6-linux-init/s6-linux-init-{{version.raw}}.tar.gz"
  strip-components = 1

  # 1.2.0.2: 67493 bytes, computed from the download.
  sha256 = {
    "1.2.0.2" = "6fad014da162c0c81924197c57d16e1a75c133b34a20e423431a1b741e907b1d"
  }
}

build {
  dependencies = {
    "gnu.org/make" = "*"
    "gnu.org/gcc"  = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--enable-pkgconfig",
      "--with-sysdeps={{deps.skarnet.org/skalibs.prefix}}/lib/skalibs/sysdeps",
      "--with-include={{deps.skarnet.org/skalibs.prefix}}/include",
      "--with-include={{deps.skarnet.org/execline.prefix}}/include",
      "--with-include={{deps.skarnet.org/s6.prefix}}/include",
      "--with-lib={{deps.skarnet.org/skalibs.prefix}}/lib",
      "--with-lib={{deps.skarnet.org/execline.prefix}}/lib",
      "--with-lib={{deps.skarnet.org/s6.prefix}}/lib",
      "--with-dynlib={{deps.skarnet.org/skalibs.prefix}}/lib",
      "--with-dynlib={{deps.skarnet.org/execline.prefix}}/lib",
      "--with-dynlib={{deps.skarnet.org/s6.prefix}}/lib",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{hw.concurrency}}",
    "make install",
  ]
}

provides = [
  "bin/s6-linux-init",
  "bin/s6-linux-init-maker",
  "bin/s6-linux-init-shutdown",
  "bin/s6-linux-init-shutdownd",
  "bin/s6-linux-init-hpr",
  "bin/s6-linux-init-telinit",
  "bin/s6-linux-init-nuke",
  "bin/s6-linux-init-umountall",
  "bin/s6-linux-init-echo",
  "bin/s6-linux-init-logouthookd",
]

test {
  script = [
    "test -x {{prefix}}/bin/s6-linux-init",
    "test -x {{prefix}}/bin/s6-linux-init-shutdown",
    # THE GENERATOR, RUN: s6-linux-init-maker writes a complete init directory.
    # -c is the absolute path the generated system will see its init directory
    # at; the tree itself is written to the last argument.
    "s6-linux-init-maker -c /etc/s6-linux-init/current -u root -G '/bin/true' -1 -p /usr/bin:/bin -m 022 initdir",
    "test -x initdir/bin/init",
    "test -x initdir/bin/halt",
    "test -x initdir/bin/poweroff",
    "test -x initdir/bin/reboot",
    "test -x initdir/bin/shutdown",
    "test -x initdir/bin/telinit",
    "test -x initdir/run-image/service/s6-linux-init-shutdownd/run",
    "test -x initdir/run-image/service/s6-linux-init-runleveld/run",
    "test -f initdir/scripts/rc.init",
    "test -f initdir/scripts/rc.shutdown",
    # The stage-1 script names the s6 binaries it will exec.
    "grep -q s6-linux-init initdir/bin/init",
  ]
}

provenance {
  read = [
    "INSTALL",   # requirements: skalibs, execline, s6; nsss and utmps optional
    "configure", # the option list printed by --help
    "COPYING",   # ISC
    "https://skarnet.org/software/s6-linux-init/",
  ]

  consulted = []

  note = <<EOT
Built on Linux (aarch64, glibc) against separately installed skalibs, execline
and s6; s6-linux-init-maker produced the init directory the test checks.

The test never runs `init` or the shutdown commands: that would act on the host.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
