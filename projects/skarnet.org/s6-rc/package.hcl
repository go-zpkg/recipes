# skarnet.org/s6-rc — a service manager for s6: services (oneshots, longruns,
# bundles) with dependencies are written as source directories, compiled by
# `s6-rc-compile` into a database, and brought up and down in dependency order
# by `s6-rc` on top of a running s6-svscan.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 0.8.0.2, the
# newest release on https://skarnet.org/software/s6-rc/ (GitHub mirror tag
# v0.8.0.2). Digest computed from the download.
#
# Read from `./configure --help`: --bootdb (default SYSCONFDIR/s6-rc/compiled/
# current), --livedir (default /run/s6-rc) and --repodir (default
# /var/lib/s6-rc/repository) are default PATHS compiled into the binaries, and
# are runtime-overridable (`s6-rc -l`, `s6-rc-compile`'s own arguments). They are
# left at upstream's defaults: those are system locations the init system owns
# (s6-linux-init), not files of this package. Needs skalibs, execline and s6.

summary = "s6-rc: service manager for s6 (compile service sources, start and stop in order)"

# COPYING: ISC licence.
license = "ISC"

versions {
  github = "skarnet/s6-rc"
}

dependencies = {
  "skarnet.org/skalibs"  = "^2"
  "skarnet.org/execline" = "^2"
  "skarnet.org/s6"       = "^2"
}

distributable {
  url              = "https://skarnet.org/software/s6-rc/s6-rc-{{version.raw}}.tar.gz"
  strip-components = 1

  # 0.8.0.2: 161779 bytes, computed from the download.
  sha256 = {
    "0.8.0.2" = "2fc0fcfe1e74b404b132a978eb316668c8bcdbc1104b3b0fe702a3d2d76caef5"
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
  "bin/s6-rc",
  "bin/s6-rc-compile",
  "bin/s6-rc-db",
  "bin/s6-rc-init",
  "bin/s6-rc-update",
]

test {
  script = [
    "test -x {{prefix}}/bin/s6-rc",
    "test -x {{prefix}}/bin/s6-rc-compile",
    # Two oneshots, `world` depending on `hello`, in a source directory; compiled
    # by the real s6-rc-compile, then read back with s6-rc-db.
    "mkdir -p src/hello src/world",
    "printf 'oneshot\\n' > src/hello/type",
    "printf 'echo hello\\n' > src/hello/up",
    "printf 'oneshot\\n' > src/world/type",
    "printf 'echo world\\n' > src/world/up",
    "printf 'hello\\n' > src/world/dependencies",
    "s6-rc-compile compiled src",
    "s6-rc-db -c compiled list all > services.out",
    "grep -qx hello services.out",
    "grep -qx world services.out",
    "s6-rc-db -c compiled all-dependencies world > deps.out",
    "grep -qx hello deps.out",
    "s6-rc-db -c compiled type world > type.out",
    "grep -qx oneshot type.out",
  ]
}

provenance {
  read = [
    "INSTALL",   # requirements: skalibs, execline, s6
    "configure", # the option list printed by --help; --bootdb, --livedir, --repodir
    "COPYING",   # ISC
    "https://skarnet.org/software/s6-rc/",
  ]

  consulted = []

  note = <<EOT
Built against separately installed skalibs, execline and s6, then run on macOS
(arm64) and Linux: s6-rc-compile accepted the two-oneshot source directory and
s6-rc-db listed both services and world's dependency.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
