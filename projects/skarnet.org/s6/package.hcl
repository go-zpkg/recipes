# skarnet.org/s6 — a small process supervision suite: `s6-svscan` watches a
# scan directory and starts one `s6-supervise` per service directory,
# `s6-svc`, `s6-svstat` and `s6-svwait` control and query them, `s6-log` is the
# logger, and the rest is the toolbox (ucspi tools, fd-holder, s6-setlock,
# s6-envdir, s6-softlimit, ...).
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 2.15.1.1, the
# newest release on https://skarnet.org/software/s6/ (GitHub mirror tag
# v2.15.1.1). Digest computed from the download.
#
# INSTALL lists skalibs and execline as requirements (the execline dependency
# can be dropped with --disable-execline; it is kept, because s6-svscanboot and
# the log helpers are written for it). Both are separate prefixes here, so each
# is named with --with-include and --with-lib. The binaries link the static
# archives (default `allstatic`), so only s6-svscanboot's #! lines need execline
# at run time: execline is a run-time dependency too.

summary = "s6: process supervision suite (s6-svscan, s6-supervise, s6-svc, s6-log, ...)"

# COPYING: ISC licence.
license = "ISC"

versions {
  github = "skarnet/s6"
}

dependencies = {
  "skarnet.org/skalibs"  = "^2"
  "skarnet.org/execline" = "^2"
}

distributable {
  url              = "https://skarnet.org/software/s6/s6-{{version.raw}}.tar.gz"
  strip-components = 1

  # 2.15.1.1: 281491 bytes, computed from the download.
  sha256 = {
    "2.15.1.1" = "62080839eb5b04d51efd4ef6e7b43e29b5d0576efce9eb319ace32ea90c05931"
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
      "--with-lib={{deps.skarnet.org/skalibs.prefix}}/lib",
      "--with-lib={{deps.skarnet.org/execline.prefix}}/lib",
      "--with-dynlib={{deps.skarnet.org/skalibs.prefix}}/lib",
      "--with-dynlib={{deps.skarnet.org/execline.prefix}}/lib",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{hw.concurrency}}",
    "make install",
  ]
}

provides = [
  "bin/s6-svscan",
  "bin/s6-svscanctl",
  "bin/s6-supervise",
  "bin/s6-svc",
  "bin/s6-svstat",
  "bin/s6-svok",
  "bin/s6-svwait",
  "bin/s6-log",
  "bin/s6-setuidgid",
  "bin/s6-envdir",
  "bin/s6-setlock",
  "bin/s6-softlimit",
  "bin/s6-tai64n",
  "bin/s6-tai64nlocal",
]

test {
  script = [
    "test -f {{prefix}}/include/s6/s6.h",
    "test -f {{prefix}}/lib/libs6.a",
    "test -x {{prefix}}/bin/s6-svscan",
    # THE REAL THING: a scan directory with one service, supervised by a
    # running s6-svscan. The service writes a marker file and sleeps; it is
    # brought up, observed with s6-svstat, taken down with s6-svc -d, and
    # the scanner is told to exit with s6-svscanctl -t.
    {
      run = <<EOT
set -e
mkdir -p scan/svc
printf '#!/bin/sh\necho started > ../../marker\nexec sleep 300\n' > scan/svc/run
chmod +x scan/svc/run
s6-svscan scan > svscan.log 2>&1 &
scanpid=$!
# supervise is started by the scanner, not by us: wait for it to exist.
n=0
until s6-svok scan/svc; do
  n=$((n + 1))
  test "$n" -lt 100
  sleep 0.1
done
s6-svwait -u -t 10000 scan/svc
s6-svstat scan/svc | grep -q '^up '
grep -qx started marker
s6-svc -d scan/svc
s6-svwait -d -t 10000 scan/svc
s6-svstat scan/svc | grep -q '^down '
s6-svscanctl -t scan
wait $scanpid
EOT
    },
    # s6-log: a line goes through a log directory, with a TAI64N stamp.
    "mkdir logdir && echo logged | s6-log -b n2 s1000000 t ./logdir && grep -q logged logdir/current",
    # s6-setlock takes and releases a lock file around a command.
    "s6-setlock -n lockfile echo locked > lock.out && grep -qx locked lock.out",
  ]
}

provenance {
  read = [
    "INSTALL",   # requirements, --disable-execline
    "configure", # the option list printed by --help
    "COPYING",   # ISC
    "https://skarnet.org/software/s6/",
  ]

  consulted = []

  note = <<EOT
Built against separately installed skalibs and execline, then run on macOS
(arm64) and Linux: s6-svscan supervised the one-service scan directory above,
s6-svwait saw it up and then down, and s6-svscanctl -t ended the scanner.

The first draft of the test called s6-svwait straight after starting the
scanner and failed with "unable to s6_svstatus_read: No such file or
directory": s6-svscan starts s6-supervise asynchronously, so the test waits for
s6-svok first.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
