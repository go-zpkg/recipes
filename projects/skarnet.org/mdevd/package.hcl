# skarnet.org/mdevd — a small mdev-compatible device manager for Linux: it
# listens to the kernel's uevents on a netlink socket, creates and removes
# device nodes in /dev according to an mdev.conf, and runs the commands that
# file names. `mdevd-coldplug` replays the events of the devices already present.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 0.1.8.2, the
# newest release on https://skarnet.org/software/mdevd/ (GitHub mirror tag
# v0.1.8.2). Digest computed from the download.
#
# INSTALL: skalibs required; nsss and execline optional. Both are left out (no
# --with-include for them): the optional execline use is a convenience for
# hooks and is not built here, and mdevd stays a one-dependency program.
# Linux only (INSTALL: "This software is Linux-specific", kernel 2.6.10+).

summary = "mdevd: mdev-compatible device manager for Linux (netlink uevents, mdev.conf)"

# COPYING: ISC licence.
license = "ISC"

platforms = ["linux"]

versions {
  github = "skarnet/mdevd"
}

dependencies = {
  "skarnet.org/skalibs" = "^2"
}

distributable {
  url              = "https://skarnet.org/software/mdevd/mdevd-{{version.raw}}.tar.gz"
  strip-components = 1

  # 0.1.8.2: 38666 bytes, computed from the download.
  sha256 = {
    "0.1.8.2" = "ce1ae0149b6a57a34f608218fd6181aa6aa68135cac2f4d931b5b417b072e244"
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
  "bin/mdevd",
  "bin/mdevd-coldplug",
]

test {
  script = [
    "test -x {{prefix}}/bin/mdevd",
    "test -x {{prefix}}/bin/mdevd-coldplug",
    # mdevd parses its configuration file (an absolute path is required) BEFORE
    # it opens the netlink socket, so both of these are decided by the parser:
    # a good file gets past it, a bad line is refused with a syntax error and
    # exit status 2, whatever the sandbox allows on netlink.
    "mkdir dev",
    "printf 'null 0:0 666\\n' > \"$PWD/mdev.conf\"",
    "timeout 2 mdevd -f \"$PWD/mdev.conf\" -d \"$PWD/dev\" 2> good.err || true",
    "test \"$(grep -c 'syntax error' good.err)\" = 0",
    "printf 'bogus line\\n' > \"$PWD/bad.conf\"",
    "mdevd -f \"$PWD/bad.conf\" -d \"$PWD/dev\" 2> bad.err || true",
    "grep -q 'syntax error' bad.err",
  ]
}

provenance {
  read = [
    "INSTALL",   # requirements: skalibs; nsss and execline optional; Linux only
    "configure", # the option list printed by --help
    "COPYING",   # ISC
    "https://skarnet.org/software/mdevd/",
  ]

  consulted = []

  note = <<EOT
Built on Linux (aarch64, glibc) against a separately installed skalibs. Run in a
container: `mdevd -f <good conf>` stayed up until `timeout` stopped it (124); a
configuration with a bad line exited 2 with "syntax error during second pass".

A good configuration cannot be asserted to START in every sandbox: opening the
netlink socket can be refused (`unable to init netlink rebroadcast socket:
Operation not permitted`, seen in the same container with `-O 4`). The test
therefore asserts the parser's verdict only.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
