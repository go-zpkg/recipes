# skarnet.org/utmps — a secure utmpx and wtmp implementation: the utmpx.h API
# (setutxent, getutxent, pututxline, ...) is a client of two small daemons,
# `utmps-utmpd` and `utmps-wtmpd`, run under a superserver (s6-ipcserver), so
# the databases need no setuid or setgid program. `utmps-write` adds an entry
# from a shell.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 0.1.3.4, the
# newest release on https://skarnet.org/software/utmps/ (GitHub mirror tag
# v0.1.3.4). Digest computed from the download.
#
# INSTALL: skalibs to build; s6 only AT RUN TIME (s6-ipcserver). It is a
# dependency here for that reason. nsss is optional and off. Defaults kept:
# the sockets are looked for at /run/utmps/.utmpd-socket and .wtmpd-socket
# (--with-utmpd-socket, --with-wtmpd-socket), the libc's utmp.h and utmpx.h are
# NOT overwritten (--enable-libc-includes off) and the headers go under
# PREFIX/include/utmps.
#
# Linux only here: the package's purpose is to supply utmpx on systems whose
# libc has none (musl), and on macOS utmpx belongs to the system.

summary = "utmps: a secure utmpx.h and wtmp implementation (utmps-utmpd, utmps-wtmpd, utmps-write)"

# COPYING: ISC licence.
license = "ISC"

platforms = ["linux"]

versions {
  github = "skarnet/utmps"
}

dependencies = {
  "skarnet.org/skalibs" = "^2"
  "skarnet.org/s6"      = "^2"
}

distributable {
  url              = "https://skarnet.org/software/utmps/utmps-{{version.raw}}.tar.gz"
  strip-components = 1

  # 0.1.3.4: 35835 bytes, computed from the download.
  sha256 = {
    "0.1.3.4" = "12dcc102ad6ac81f81aecc4950733db94f35081947054b9b1473cac5c90810bc"
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
      "--with-lib={{deps.skarnet.org/skalibs.prefix}}/lib",
      "--with-dynlib={{deps.skarnet.org/skalibs.prefix}}/lib",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{hw.concurrency}}",
    "make install",
  ]
}

provides = [
  "bin/utmps-utmpd",
  "bin/utmps-wtmpd",
  "bin/utmps-write",
]

test {
  script = [
    "test -f {{prefix}}/include/utmps/utmpx.h",
    "test -f {{prefix}}/lib/libutmps.a",
    "test -f {{prefix}}/lib/pkgconfig/libutmps.pc",
    # THE REAL THING: a utmpd served by s6-ipcserver in a directory of our own,
    # and an entry written to it through its socket with utmps-write.
    {
      run = <<EOT
set -e
mkdir run
cd run
s6-ipcserver .utmpd-socket utmps-utmpd &
srv=$!
n=0
until test -S .utmpd-socket; do
  n=$((n + 1))
  test "$n" -lt 100
  sleep 0.1
done
utmps-write -u -U "$PWD/.utmpd-socket" -l tester x1 USER_PROCESS tty1
kill $srv
wait $srv || true
test -s utmp
grep -q tester utmp
EOT
    },
  ]
}

provenance {
  read = [
    "INSTALL",           # requirements: skalibs; s6 at run time; nsss optional
    "configure",         # the option list printed by --help; the socket defaults
    "COPYING",           # ISC
    "doc/utmps-utmpd.html", # "expects to create, read and modify a file named utmp in the directory it is launched in"
    "src/utmps/utmps-write.c", # the -u, -U and -l options
    "https://skarnet.org/software/utmps/",
  ]

  consulted = []

  note = <<EOT
Built on Linux (aarch64, glibc) against a separately installed skalibs.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
