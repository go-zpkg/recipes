# github.com/linux-audit/audit-userspace — the Linux Audit userspace: libaudit,
# libauparse, auditd and its tools. Batch 2 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): systemd's `audit` option (meson_options.txt:428) links
# libaudit for audit event logging, and linux-pam's own `audit` option takes it
# too (a later rebuild of that recipe).
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN configure.ac, init.d/Makefile.am and
# AGENTS.md, at 4.2.1 — the newest tag: `git ls-remote --tags` lists v4.2.1
# last, after v4.2.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# THE TAG ARCHIVE CARRIES NO configure: AGENTS.md "Building" runs
# `autoreconf -f --install` first, so autoconf, automake and libtool are build
# dependencies.
#
# OPTIONS (configure.ac), every one that detects or chooses:
#   --with-python3 (:157) default AUTO-detects python3-config: OFF (`no`), the
#       bindings need swig and a Python; --with-golang (:196) default auto:
#       OFF. Both would otherwise be taken from whatever the host has.
#   --disable-zos-remote (:238): default yes, and it REQUIRES openldap's lber
#       (:243-252, an error when absent): no recipe, OFF.
#   --enable-gssapi-krb5 (:269) default no; --enable-tls (:291) default no
#       (needs OpenSSL, not wanted here); --enable-experimental (:354) default
#       no. All left at their defaults, not passed.
#   --with-libwrap (:463) default no; --with-apparmor (:452) default no;
#       --with-io_uring (:506) default no; --with-arm/aarch64/riscv: default
#       no, per-arch syscall tables. Left at their defaults.
#   --with-nftables (:516) default yes: only chooses the firewall command a
#       plugin runs (USE_NFTABLES); stated.
#   LIBCAP_NG_PATH (:535) probes libcap-ng and lowers plugin capabilities when
#       found: no recipe, so `--without-libcap-ng`.
#   --disable-listener (:225) / --disable-legacy-actions (:260): left at their
#       defaults (yes).
# PREFIX: init.d/Makefile.am:33, :52-53 install the unit files and tmpfiles.d
# under $(prefix)/lib; configure.ac:78-85 puts the run directory under
# /run when `--runstatedir` is not given, so it is given, inside the prefix.

summary = "Linux Audit userspace: libaudit, libauparse and auditd"

# COPYING is GPL-2.0, COPYING.LIB LGPL-2.1: the libraries are LGPL, the daemon
# and tools GPL.
license = "GPL-2.0-or-later AND LGPL-2.1-or-later"

platforms = ["linux"]

versions {
  # Tags are `v4.2.1`.
  github = "linux-audit/audit-userspace"
}

distributable {
  # The GitHub tag archive: no signed tarball was found.
  url              = "https://github.com/linux-audit/audit-userspace/archive/refs/tags/v{{version.raw}}.tar.gz"
  strip-components = 1

  # 4.2.1: 756167 bytes, `shasum -a 256` of the downloaded archive; see
  # provenance.note for why this is a cross-check and not a signature.
  sha256 = {
    "4.2.1" = "42876d195ee2ded19e5f72d7664096eee314928aa36ad346719ba5b25818fc84"
  }
}

build {
  dependencies = {
    "gnu.org/autoconf"           = "*"
    "gnu.org/automake"           = "*"
    "gnu.org/libtool"            = "*"
    "gnu.org/m4"                 = "*"
    "gnu.org/make"               = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--sysconfdir={{prefix}}/etc",
      "--localstatedir={{prefix}}/var",
      "--runstatedir={{prefix}}/var/run",
      "--without-python3",
      "--without-golang",
      "--without-libcap-ng",
      "--disable-zos-remote",
      "--with-nftables",
      "--disable-static",
    ]

    LDFLAGS = "-Wl,-rpath,{{prefix}}/lib"
  }

  script = [
    "autoreconf -f --install",
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

provides = [
  "sbin/auditd",
  "sbin/auditctl",
  "sbin/ausearch",
  "sbin/aureport",
]

test {
  script = [
    "test -f \"{{prefix}}/include/libaudit.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/audit.pc\"",
    "test -x \"{{prefix}}/sbin/auditctl\"",
  ]
}

provenance {
  read = [
    "configure.ac",         # :32 version; :155-221 python3 and golang; :225-266 listener, zos-remote, legacy actions; :269-352 gssapi and tls; :452-535 apparmor, libwrap, io_uring, nftables, libcap-ng
    "init.d/Makefile.am",   # :33, :52-59 unit and tmpfiles.d directories
    "AGENTS.md",            # Building: autoreconf, configure
    "https://github.com/linux-audit/audit-userspace (git ls-remote --tags)",
  ]

  consulted = []

  note = <<EOT
  source     https://github.com/linux-audit/audit-userspace/archive/refs/tags/v4.2.1.tar.gz
  sha256     42876d195ee2ded19e5f72d7664096eee314928aa36ad346719ba5b25818fc84

⚠ NO SIGNATURE. No detached signature or project-published checksum was found
for this archive; the digest is the one this recipe's author computed on the
GitHub tag archive. GitHub regenerates tag archives from the tag's commit, so
a mismatch means a changed archive or a moved tag, to be investigated.

⛔ NOT BUILT. Unverified (m4/cap-ng.m4:6 was read: `--with-libcap-ng=[auto/yes/no]`
exists, so `--without-libcap-ng` is its `no`); that the install is clean of
absolute paths outside the prefix (only init.d/Makefile.am was read); that
the build host has linux/audit.h kernel headers (configure.ac:86-90 probes
them); and the `provides` list.
EOT
}
