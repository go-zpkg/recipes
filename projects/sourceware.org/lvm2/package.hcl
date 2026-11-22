# sourceware.org/lvm2 — the LVM2 sources, built DEVICE-MAPPER ONLY: libdevmapper
# (libdm), the dmsetup tool and its header, which is all cryptsetup links.
# Step 3 of go-zpkg/recipes#348 (design go-zpkg/packages#440):
# lvm2 (device-mapper) -> cryptsetup.
#
# ⛔ WRITTEN FROM LVM2'S OWN FILES (configure.ac, Makefile.in, make.tmpl.in,
# libdm/), at 2.03.44 — the newest tarball in https://sourceware.org/pub/lvm2/
# (the listing has no 2.04 or later series).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established
# is the inputs, each traced to a line in lvm2's own files.

summary = "LVM2 device-mapper library (libdevmapper) and dmsetup"

# Three licence files ship (COPYING, COPYING.LIB, COPYING.BSD). The library
# libdevmapper is LGPL-2.1 (COPYING.LIB); dmsetup and the LVM tools are GPL-2.
# Stated from the project's long-standing split, not re-read here: see
# provenance.note.
license = "GPL-2.0-only AND LGPL-2.1-only"

versions {
  url   = "https://sourceware.org/pub/lvm2/"
  match = "/LVM2\\.2\\.03\\.\\d+\\.tgz/"
  strip = ["/LVM2\\./", "/\\.tgz/"]
}

distributable {
  url              = "https://sourceware.org/pub/lvm2/LVM2.{{version.raw}}.tgz"
  strip-components = 1

  # 2.03.44: 3231228 bytes. Recorded with `zpkb sourcepin --sig auto`
  # (signature verified, see provenance.note) and confirmed by an independent
  # `shasum -a 256` of the same file.
  sha256 = {
    "2.03.44" = "42f829927d2d459f5733fcdb38a5bf2455a8b84072193092450a9c69d6596eca"
  }
}

build {
  dependencies = {
    "gnu.org/make"               = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir={{prefix}}/lib",

      # configure.ac:1399-1401 `--enable-pkgconfig` defaults to "no", and it is
      # what installs devmapper.pc (libdm/Makefile.in:149-151), the file
      # cryptsetup finds libdevmapper through. ON.
      "--enable-pkgconfig",

      # configure.ac:222-231 — libaio, libnvme, liburing, systemd and udev are
      # `with_*` options defaulting to "yes", each then detected on the BUILD
      # host: five host-dependent choices. All pinned off. libudev would also
      # come from systemd.io, which depends on cryptsetup once this chain is
      # turned on, and so would be a dependency cycle.
      "--without-libaio",
      "--without-libnvme",
      "--without-liburing",
      "--without-systemd",
      "--without-udev",
      "--without-blkid",

      # configure.ac:1261-1264 udev_sync defaults to "no" and :1281-1284
      # udev_rules follows it; stated.
      "--disable-udev_sync",
      "--disable-udev_rules",

      # configure.ac:1535-1538 `--disable-selinux`: on Linux the default is
      # "yes" (:42) and the libraries are then detected on the build host.
      "--disable-selinux",

      # configure.ac:715-717 readline defaults to "maybe" — a host detection —
      # and only the lvm shell in tools/ uses it. OFF.
      "--disable-readline",

      # configure.ac:1413-1428 — fsadm and blkdeactivate default to "yes" on
      # Linux (:43-45); shell scripts for the LVM side this build leaves out.
      "--disable-fsadm",
      "--disable-blkdeactivate",
      "--disable-lvmimportvdo",
    ]
  }

  # Makefile.in:60 `device-mapper: tools.device-mapper daemons.device-mapper
  # man.device-mapper`, with libdm built first (:58-59); make.tmpl.in:444
  # `install_device_mapper: install_device-mapper`. The LVM tools (lvm, pvs,
  # lvs …) are never built.
  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }} device-mapper",
    "make install_device-mapper",
  ]
}

# libdm/dm-tools/Makefile.in:77-81: dmsetup installs to $(sbindir), with
# dmstats and dmvdostats as links to it.
provides = [
  "sbin/dmsetup",
]

test {
  script = [
    "test -x \"{{prefix}}/sbin/dmsetup\"",
    "test -f \"{{prefix}}/include/libdevmapper.h\"",
    # libdm/Makefile.in:151 installs libdevmapper.pc under the name devmapper.pc.
    "test -f \"{{prefix}}/lib/pkgconfig/devmapper.pc\"",
    # No kernel interface is needed to print the library and driver versions
    # banner of the tool itself.
    "\"{{prefix}}/sbin/dmsetup\" --version >/dev/null",
  ]
}

provenance {
  read = [
    "configure.ac",          # :36-57 per-OS defaults; :222-231 the with_* options; :715 readline; :958 devmapper; :1261-1292 udev; :1399 pkgconfig; :1413-1435 scripts; :1535 selinux
    "Makefile.in",           # :21 SUBDIRS; :58-61 the device-mapper targets
    "make.tmpl.in",          # :388-453 device-mapper and install_device-mapper
    "libdm/Makefile.in",     # :116-151 install_pkgconfig and devmapper.pc
    "libdm/dm-tools/Makefile.in", # :28-34 and :77-81 dmsetup and its links
    "https://sourceware.org/pub/lvm2/", # the release listing, the .asc beside the archive and mcsontos.pubkey.asc
  ]

  consulted = []

  note = <<EOT
  signature  https://sourceware.org/pub/lvm2/LVM2.2.03.44.tgz.asc
  signer     D501A478440AE2FD130A1BE8B9112431E509039F (RSA 4096, expires
             2029-09-23), signed 2026-10-27
  identity   Marian Csontos <marian.csontos@gmail.com>
  key from   https://sourceware.org/pub/lvm2/mcsontos.pubkey.asc, in the same
             directory as the tarball

⚠ THE FINGERPRINT IS PUBLISHED BY NO PAGE THE PROJECT CONTROLS that was read:
it came from the signature's own issuer field (`gpg --list-packets`), and
that key was then found in the one file the release directory carries for the
purpose. The warrant is the host's own directory — continuity with the host,
not independence. No keyserver was asked.

Licences were NOT re-read from COPYING in this session: the SPDX line is the
project's usual split (COPYING.LIB for libdevmapper, COPYING for the rest).

⛔ NOT BUILT. Unverified: that every `--without-*` spelling above is the one
the 2.03.44 configure accepts (read at configure.ac:222-231); that
`make device-mapper` needs no gawk or other tool beyond those declared; and
that dmsetup runs with no /dev/mapper/control.
EOT
}
