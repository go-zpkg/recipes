# skarnet.org/s6-linux-utils — Linux-specific small utilities for init and
# early boot: s6-mount, s6-umount, s6-swapon, s6-swapoff, s6-chroot,
# s6-pivotchroot, s6-hostname, s6-freeramdisk, s6-ps, s6-logwatch, rngseed and
# fstab2s6rc (an /etc/fstab to s6-rc source directories converter).
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 2.6.4.1, the
# newest release on https://skarnet.org/software/s6-linux-utils/ (GitHub
# mirror tag v2.6.4.1). Digest computed from the download.
#
# ⛔ INSTALL SAYS "skalibs" AND THE BUILD SAYS "skalibs AND execline". Built with
# skalibs alone, make stops at
#   src/s6-linux-utils/fstab2s6rc.c:23:10: fatal error: execline/config.h: No
#   such file or directory
# so execline's headers are a build input (only the header: fstab2s6rc writes
# the path of execline's binaries into the services it generates), and execline
# is therefore a dependency here.
#
# Linux only: the tools call mount(2), swapon(2), pivot_root(2) and read /proc.
# The default rngseed directory (--with-seed-dir, /var/lib/rngseed) is a runtime
# path, overridable with `rngseed -d`; it is left as upstream has it.

summary = "s6-linux-utils: s6-mount, s6-chroot, s6-ps, rngseed, fstab2s6rc and other Linux init utilities"

# COPYING: ISC licence.
license = "ISC"

platforms = ["linux"]

versions {
  github = "skarnet/s6-linux-utils"
}

dependencies = {
  "skarnet.org/skalibs"  = "^2"
  "skarnet.org/execline" = "^2"
}

distributable {
  url              = "https://skarnet.org/software/s6-linux-utils/s6-linux-utils-{{version.raw}}.tar.gz"
  strip-components = 1

  # 2.6.4.1: 54889 bytes, computed from the download.
  sha256 = {
    "2.6.4.1" = "16e1a5b5a2b4a98674b4a9719612adb79588e3c20c4083360278ea38f2d32129"
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
      "--with-include={{deps.skarnet.org/execline.prefix}}/include",
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
  "bin/s6-mount",
  "bin/s6-umount",
  "bin/s6-swapon",
  "bin/s6-swapoff",
  "bin/s6-chroot",
  "bin/s6-pivotchroot",
  "bin/s6-hostname",
  "bin/s6-freeramdisk",
  "bin/s6-ps",
  "bin/s6-logwatch",
  "bin/rngseed",
  "bin/fstab2s6rc",
]

test {
  script = [
    "test -x {{prefix}}/bin/s6-mount",
    "test -x {{prefix}}/bin/s6-chroot",
    # s6-ps reads /proc and lists processes: it must list itself.
    "s6-ps > ps.out",
    "grep -q s6-ps ps.out",
    # fstab2s6rc turns an fstab line into an s6-rc oneshot source directory.
    "printf 'tmpfs /mnt tmpfs defaults 0 0\\n' > fstab",
    "fstab2s6rc -F fstab -a services",
    "test -d services/mount-mnt",
    "grep -qx oneshot services/mount-mnt/type",
    "test -f services/mount-mnt/up",
  ]
}

provenance {
  read = [
    "INSTALL",   # says skalibs only; see the header
    "configure", # the option list printed by --help; --with-seed-dir
    "COPYING",   # ISC
    "https://skarnet.org/software/s6-linux-utils/",
  ]

  consulted = []

  note = <<EOT
Built on Linux (aarch64, glibc) against separately installed skalibs and
execline; the first attempt, with skalibs only, failed as the header says.
s6-ps listed itself, fstab2s6rc turned `tmpfs /mnt tmpfs defaults 0 0` into
services/mount-mnt (type oneshot, an `up` file).

The mount, swap, chroot and pivot tools need root and are not run by the test.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
