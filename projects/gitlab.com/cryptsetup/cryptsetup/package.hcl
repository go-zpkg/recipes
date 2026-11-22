# gitlab.com/cryptsetup/cryptsetup — libcryptsetup and the cryptsetup,
# veritysetup and integritysetup tools: LUKS, dm-crypt, dm-verity and
# dm-integrity volume management. Step 3 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): lvm2 (device-mapper) -> popt -> cryptsetup, so that
# systemd.io can turn on libcryptsetup (and with it cryptenroll, veritysetup
# and homed's volume handling).
#
# ⛔ WRITTEN FROM CRYPTSETUP'S OWN FILES (configure.ac), at 2.8.8 — the newest
# release of the v2.8 series in https://www.kernel.org/pub/linux/utils/cryptsetup/
# (see provenance.note for what that listing was and was not read to show).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established
# is the inputs, each traced to a line in cryptsetup's own files.

summary = "cryptsetup: LUKS / dm-crypt / dm-verity / dm-integrity volume management"

# COPYING: the GPL version 2 text (:2) whose notice grants "any later version"
# (:299), followed at :342-349 by the project's added exception allowing
# linking against the OpenSSL library.
license = "GPL-2.0-or-later WITH cryptsetup-OpenSSL-exception"

versions {
  url   = "https://www.kernel.org/pub/linux/utils/cryptsetup/v2.8/"
  match = "/cryptsetup-2\\.8\\.\\d+\\.tar\\.xz/"
  strip = ["/cryptsetup-/", "/\\.tar\\.xz/"]
}

distributable {
  url              = "https://www.kernel.org/pub/linux/utils/cryptsetup/v2.8/cryptsetup-{{version.raw}}.tar.xz"
  strip-components = 1

  # 2.8.8: 11951044 bytes. Recorded with `zpkb sourcepin --sig auto
  # --sig-covers decompressed` (signature verified, see provenance.note) and
  # confirmed by an independent `shasum -a 256` of the same file. The digest is
  # of the .tar.xz a build downloads; the signature covers the decompressed tar.
  sha256 = {
    "2.8.8" = "3acfa685f2dd7fcc832e0b77bc7093aa7da554a51ce8dafbb4138eaa854eee35"
  }
}

dependencies = {
  "sourceware.org/lvm2"                      = "2"
  "openssl.org"                              = "^3"
  "github.com/json-c/json-c"                 = "*"
  "github.com/util-linux/util-linux"         = "*"
  "github.com/rpm-software-management/popt"  = "1"
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

      # configure.ac:59-68 `--disable-asciidoc` defaults to yes and then
      # REQUIRES asciidoctor (:65-66, an error); the tarball ships the
      # generated pages (:71 tests for man/cryptsetup-open.8), which are then
      # re-used. OFF.
      "--disable-asciidoc",

      # configure.ac:500-502 — the backend defaults to openssl; stated so that
      # a change of default cannot move it. libcrypto is found by pkg-config
      # (:331), and OpenSSL 3.2+ provides Argon2 (:348), so the bundled
      # reference Argon2 (:558 "slow") is not compiled in.
      "--with-crypto_backend=openssl",

      # configure.ac:94-96 and :505-513 — kernel keyring and the kernel crypto
      # API (benchmark, tcrypt) both default ON; each only checks Linux headers.
      "--enable-keyring",
      "--enable-kernel_crypto",

      # configure.ac:140-142 external LUKS2 tokens (dlopen of plugins from
      # ${libdir}/cryptsetup, :856) default ON; stated.
      "--enable-external-tokens",

      # configure.ac:164-166 online reencryption default ON; stated.
      "--enable-luks2-reencryption",

      # configure.ac:432-445 the three tools default ON; stated.
      "--enable-cryptsetup",
      "--enable-veritysetup",
      "--enable-integritysetup",

      # configure.ac:581-583 libblkid for signature detection and wiping,
      # default ON, from util-linux (:586 pkg-config blkid).
      "--enable-blkid",

      # configure.ac:613-616 hardware OPAL support, default ON; it only
      # compiles in when the kernel headers declare the OPAL ioctls (:620-631,
      # else a warning, not an error).
      "--enable-hw-opal",

      # configure.ac:154-161 the LUKS2 ssh-token plugin needs libssh (:490)
      # and argp (:492): no libssh recipe exists. OFF.
      "--disable-ssh-token",

      # configure.ac:447-449 selinux defaults ON and is then probed on the
      # build host; no selinux recipe exists. OFF.
      "--disable-selinux",

      # configure.ac:451-453 / :474-479 udev synchronisation of the dm cookie.
      # lvm2 here is built --without-udev, and libudev would come from
      # systemd.io, which depends on this recipe: a dependency cycle. OFF.
      "--disable-udev",

      # configure.ac:827-835 and :704-713: the tmpfiles directory is read from
      # systemd.pc on the build host (host-dependent, and a cycle). `no` skips
      # installing the tmpfiles.d file.
      "--with-tmpfilesdir=no",

      # configure.ac:204-214 pwquality and :229-238 passwdqc are options with
      # no default value (OFF); neither has a recipe. Stated here, not passed.
      # configure.ac:186-194 --enable-fips, :218-225 fuzz targets and :422-430
      # the static tools are likewise OFF by default and left so.
    ]

    PKG_CONFIG_PATH = "{{deps.sourceware.org/lvm2.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib64/pkgconfig:{{deps.github.com/json-c/json-c.prefix}}/lib/pkgconfig:{{deps.github.com/json-c/json-c.prefix}}/lib64/pkgconfig:{{deps.github.com/util-linux/util-linux.prefix}}/lib/pkgconfig:{{deps.github.com/rpm-software-management/popt.prefix}}/lib/pkgconfig"

    # configure.ac:120 and :179 link libuuid and libpopt with AC_CHECK_LIB,
    # which finds them through -L; each is also a runtime rpath.
    LDFLAGS = "-L{{deps.github.com/util-linux/util-linux.prefix}}/lib -L{{deps.github.com/rpm-software-management/popt.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/lvm2.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib64 -Wl,-rpath,{{deps.github.com/json-c/json-c.prefix}}/lib -Wl,-rpath,{{deps.github.com/json-c/json-c.prefix}}/lib64 -Wl,-rpath,{{deps.github.com/util-linux/util-linux.prefix}}/lib -Wl,-rpath,{{deps.github.com/rpm-software-management/popt.prefix}}/lib"

    # configure.ac:91-92 AC_CHECK_HEADERS uuid/uuid.h and libdevmapper.h, and
    # :485 json-c/json.h, are found through the include path, not pkg-config.
    CPPFLAGS = "-I{{deps.github.com/util-linux/util-linux.prefix}}/include -I{{deps.sourceware.org/lvm2.prefix}}/include -I{{deps.github.com/rpm-software-management/popt.prefix}}/include"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

provides = [
  "sbin/cryptsetup",
  "sbin/veritysetup",
  "sbin/integritysetup",
]

test {
  script = [
    "test -x \"{{prefix}}/sbin/cryptsetup\"",
    "test -x \"{{prefix}}/sbin/veritysetup\"",
    "test -x \"{{prefix}}/sbin/integritysetup\"",
    "test -f \"{{prefix}}/include/libcryptsetup.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libcryptsetup.pc\"",
    # Prints its version without touching any device.
    "\"{{prefix}}/sbin/cryptsetup\" --version | grep {{version.raw}}",
  ]
}

provenance {
  read = [
    "configure.ac",  # :59-68 asciidoc; :94-161 keyring, external tokens, ssh-token; :164 reencryption; :179 popt; :330-350 the openssl backend; :432-453 tools, selinux, udev; :456 devmapper; :484 json-c; :500-513 backend and kernel crypto; :539-558 argon2; :581-611 blkid; :613-632 opal; :704-713 and :827-835 tmpfiles; :849-858 token path
    "SECURITY.md",   # :9 names the maintainer's key
    "COPYING",       # :2 GPL v2; :299 later versions; :342-349 the OpenSSL exception
    "https://www.kernel.org/pub/linux/utils/cryptsetup/v2.8/", # the release directory
  ]

  consulted = []

  note = <<EOT
  signature  https://www.kernel.org/pub/linux/utils/cryptsetup/v2.8/cryptsetup-2.8.8.tar.sign
  covers     the DECOMPRESSED tar (one signature serves every compression), so
             `--sig-covers decompressed`; the pinned sha256 is of the .tar.xz
  signer     2A2918243FDE46648D0686F9D9B0577BD93E98FC (RSA 4096, expires
             2031-11-27), signed 2026-09-07T11:10:10Z
  identity   Milan Broz <gmazyland@gmail.com>
  fingerprint named by the project: cryptsetup-2.8.8 SECURITY.md:9
  key from   keyserver.ubuntu.com. The copy at keys.openpgp.org carried no
             user ID and sourcepin refused it ("v4 entity without any
             identities"). The key is accepted ONLY because it carries the
             fingerprint the project's own SECURITY.md names; the keyserver is
             a courier, not a warrant.

Only the v2.8 series was listed (the directory this recipe resolves versions
from); newer series directories (v2.9, v3.0) were NOT looked for, so "newest"
means newest of v2.8.

⛔ NOT BUILT. Unverified: that the host provides Linux headers new enough for
the keyring and kernel crypto checks (configure.ac:98 and :510 are errors, not
warnings, when the headers are missing); that `--disable-udev` and the other
spellings above are accepted by the shipped configure; and that every
dependency prefix's lib directory is the one named in LDFLAGS (lib64 is listed
for openssl and json-c only).
EOT
}
