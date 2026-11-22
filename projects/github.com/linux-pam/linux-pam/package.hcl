# github.com/linux-pam/linux-pam — Linux-PAM: libpam, libpam_misc, libpamc, the
# PAM modules and their helpers. Step 4 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): systemd.io turns on pam, homed and pamconfdir once this
# recipe exists (homed's pam_systemd_home needs HAVE_PAM, meson.build:1601-1609
# of systemd 262.2).
#
# ⛔ WRITTEN FROM LINUX-PAM'S OWN FILES (meson.build, meson_options.txt,
# modules/module-meson.build, libpam/meson.build), at 1.7.3 — the newest tag:
# `git ls-remote --tags` of the project lists v1.7.3 last, with nothing above it.
# 1.7.3 builds with meson ONLY (the release tarball carries no configure).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# ⛔ PREFIX-RELATIVE CONFIGURATION. meson.build:27 `sysconfdir = prefix / sysconfdir`
# (so `--sysconfdir=etc` is {{prefix}}/etc) and PAM reads <sysconfdir>/pam.d
# (SYSCONFDIR, :44). The default `vendordir` is the ABSOLUTE /usr/share/pam
# (meson_options.txt:90), and modules/module-meson.build:265-284 install every
# default config (access.conf, limits.conf, ...) into vendor_sconfigdir: with the
# default that would write the host's /usr/share/pam. `-Dvendordir=` (empty,
# meson.build:85-86) sends them to {{prefix}}/etc/security instead.
# `localstatedir` is '/' / localstatedir (:24): absolute, but only the sepermit
# lock directory uses it (module-meson.build:76) and pam_sepermit needs selinux,
# which is off, so nothing is installed there.
#
# OPTIONS, every one that detects or chooses (meson_options.txt):
#   OFF, each with its reason:
#     audit (:7)     libaudit has no recipe yet (audit-userspace is the next PR of
#                    the series); PAM is rebuilt with it ON when it lands.
#     econf (:9)     libeconf: no recipe.
#     logind (:11), elogind (:13)   meson.build:323-332 wants libsystemd >= 254:
#                    systemd.io depends on this recipe, so a dependency CYCLE.
#     selinux (:19)  no recipe yet (libselinux is a later PR).
#     pwaccess (:17) libpwaccess: no recipe, no upstream package of note.
#     nis (:21)      needs libnsl (meson.build:460): no recipe.
#     openssl (:15)  already `disabled` upstream; pam_timestamp then uses its
#                    own SHA-1 (module-meson.build:87-92).
#     pam_userdb (:93) needs libdb/gdbm/ndbm (:350-413): none declared.
#     pam_lastlog (:100) already disabled upstream (utmp-based, deprecated).
#     i18n (:3)      avoids the host's gettext (po/meson.build:1).
#     docs (:5)      needs xsltproc, xmllint, a DocBook RNG and XML catalog on
#                    the host (meson.build:488-605); the DocBook DTD recipe is a
#                    later step. The man pages are skipped, not the code.
#     examples (:24), xtests (:36)   no installed function.
#   ON / stated: pam_unix (:102) with lckpwdf (:26): needs libxcrypt, declared
#   (meson.build:250, `libxcrypt` pkg-config module).
#   Left at upstream defaults: pam-debug, pamlocking, read-both-confs,
#   usergroups, misc-conv-bufsize 4096, kernel-overflow-uid 65534, uidmin 1000,
#   pam_unix-try-getspnam false, db auto (inert, pam_userdb is off).
#   systemdunitdir is stated: unset, meson.build:334-346 asks the host's
#   `systemd` pkg-config module, a host-dependent choice.

summary = "Linux-PAM: pluggable authentication modules library and modules"

# meson.build:3 `license: 'BSD-3-Clause OR GPL-2.0-or-later'`.
license = "BSD-3-Clause OR GPL-2.0-or-later"

platforms = ["linux"]

versions {
  # Tags are `v1.7.3`.
  github = "linux-pam/linux-pam"
}

distributable {
  # The SIGNED release tarball (with .tar.xz.asc beside it).
  url              = "https://github.com/linux-pam/linux-pam/releases/download/v{{version.raw}}/Linux-PAM-{{version.raw}}.tar.xz"
  strip-components = 1

  # 1.7.3: 515580 bytes. Recorded with `zpkb sourcepin --sig auto` (signature
  # verified, see provenance.note) and confirmed by an independent
  # `shasum -a 256` of the same file.
  sha256 = {
    "1.7.3" = "2ce4765fd49df6693771ef2941f81e33d8ee14b94a81a5c7b369aa3b137b85a5"
  }
}

dependencies = {
  "github.com/besser82/libxcrypt" = "*"
}

build {
  dependencies = {
    "mesonbuild.com"             = "*"
    "ninja-build.org"            = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir={{prefix}}/lib",
      "--sysconfdir=etc",
      "--localstatedir=var",
      "--buildtype=release",
      "--wrap-mode=nofallback",

      # Nothing outside the prefix (see the header).
      "-Dvendordir=",
      "-Dsystemdunitdir={{prefix}}/lib/systemd/system",

      "-Daudit=disabled",
      "-Deconf=disabled",
      "-Dlogind=disabled",
      "-Delogind=disabled",
      "-Dselinux=disabled",
      "-Dpwaccess=disabled",
      "-Dnis=disabled",
      "-Dopenssl=disabled",
      "-Dpam_userdb=disabled",
      "-Dpam_lastlog=disabled",
      "-Di18n=disabled",
      "-Ddocs=disabled",
      "-Dexamples=false",
      "-Dxtests=false",
      "-Dpam_unix=enabled",
      "-Dlckpwdf=true",
    ]

    PKG_CONFIG_PATH = "{{deps.github.com/besser82/libxcrypt.prefix}}/lib/pkgconfig"
    LDFLAGS         = "-Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.github.com/besser82/libxcrypt.prefix}}/lib"
  }

  script = [
    "meson setup build $ARGS",
    "meson compile -C build",
    "meson install -C build",
  ]
}

# Executables of modules/module-meson.build that are installed unconditionally
# (:289, :322, :370, :413, :423) plus the namespace helper script (:332-342).
provides = [
  "sbin/faillock",
  "sbin/mkhomedir_helper",
  "sbin/pam_namespace_helper",
  "sbin/pam_timestamp_check",
  "sbin/pwhistory_helper",
  "sbin/unix_chkpwd",
]

test {
  script = [
    "test -x \"{{prefix}}/sbin/unix_chkpwd\"",
    # libpam/meson.build:66-72 filebase `pam`; systemd's meson.build:1205 asks
    # for the `pam` module.
    "test -f \"{{prefix}}/lib/pkgconfig/pam.pc\"",
    "test -f \"{{prefix}}/include/security/pam_appl.h\"",
    "test -f \"{{prefix}}/lib/security/pam_unix.so\"",
    "test -f \"{{prefix}}/etc/security/limits.conf\"",
  ]
}

provenance {
  read = [
    "meson.build",                   # :16-31 directories; :84-97 vendordir; :232-331 audit, libcrypt, econf, selinux, openssl, logind; :334-347 systemdunitdir; :350-485 userdb, lastlog, unix, nis; :488-605 docs
    "meson_options.txt",             # every option, :3-105
    "modules/module-meson.build",    # per-module dependencies and every install rule
    "libpam/meson.build",            # :46-73 libpam and pam.pc
    "po/meson.build",                # :1 gettext
    "pgp.keys.asc",                  # :2 the primary key fingerprint
    "https://github.com/linux-pam/linux-pam (git ls-remote --tags)",
  ]

  consulted = []

  note = <<EOT
  signature  https://github.com/linux-pam/linux-pam/releases/download/v1.7.3/Linux-PAM-1.7.3.tar.xz.asc
  signer     signing subkey FB3DCD19FF874735E4F61CE64E9FE8522F160EC2 of the
             primary key 7BECFE3AF7B280BB52FF77F104BA4521C996DDE1
             (RSA 4096), signed 2026-09-24T17:09:52Z
  identity   Dmitry V. Levin <ldv@strace.io>
  fingerprint named by the project: the release tarball's own pgp.keys.asc:2
             lists the primary key 7BECFE3A…DDE1
  key from   keyserver.ubuntu.com; verified by `zpkb sourcepin --sig auto
             --key <file> --fingerprint 7BECFE3A…DDE1` against that file, the
             keyserver being a courier and not a warrant.

⛔ NOT BUILT. Unverified: that every `-D` spelling above is accepted by 1.7.3's
meson (`-Dvendordir=` with an empty value in particular, read at
meson.build:85); that libxcrypt's `libxcrypt.pc` satisfies meson.build:250; that
the `provides` list matches an install; that the build host has the kernel
headers pam_keyinit and pam_namespace probe for (meson.build:199, :191).
EOT
}
