# github.com/tpm2-software/tpm2-tss — the TCG TPM2 Software Stack: the SAPI, ESAPI,
# marshalling (mu), error decoding (rc) and TCTI libraries. Batch 3 of
# go-zpkg/recipes#348 (design go-zpkg/packages#440): systemd's `tpm2` option
# (meson_options.txt:470) enables the TPM2 measurements, systemd-cryptenroll's
# TPM2 slots, systemd-pcrextend and the TPM2 credentials; it needs tss2-esys,
# tss2-rc and tss2-mu, and dlopens the tss2 libraries.
#
# ⛔ WRITTEN FROM TPM2-TSS'S OWN FILES (configure.ac, Makefile.am, LICENSE) at
# 4.2.2, the newest stable tag: `git ls-remote --tags` lists 4.2.2 above 4.2.1,
# 4.2.2-rc0 and the signed-tag duplicate `4.2.2s` are not releases.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# WHAT IS BUILT. ESYS (configure.ac:114-119) with the OpenSSL backend (:149-154,
# :171-196); the TCTIs that need no further library (device :239, mssim :247,
# swtpm :255, pcap :262, null :268, cmd :286, the spi and i2c helpers :295,
# :364). OFF, with the reason each time:
#   --disable-fapi (:123-129): FAPI needs json-c (:207-208), libcurl (:210-211)
#       and libuuid (:214-215); systemd does not use it.
#   --disable-policy (:141-147): libtss2-policy needs json-c and libuuid (:207,
#       :214); systemd does not use it.
#   tcti-libtpms (:274-284): without an argument it is ON if libtpms.h is found
#       on the host, a leak; no libtpms recipe. OFF.
#   tcti-spi-ltt2go (:304-319) and the two ftdi TCTIs (:349-357, :373-381) probe
#       libusb-1.0 and libftdi with PKG_CHECK_MODULES, found on the host when
#       present; USB bridges to external TPMs, not used by systemd. OFF.
#   tcti-spidev (:327-337) is an `auto` probe of linux/ioctl.h; OFF.
#   doxygen (configure:1790-1800, DX_DOXYGEN_FEATURE at :675): found on the host,
#       it would build the manual pages. OFF.
#   unit and integration tests (:100-112, :472) need cmocka and a TPM simulator.
#       Left at their default `no`.
# THE INSTALL STEP HAS SIDE EFFECTS OUTSIDE THE PREFIX. Makefile.am:1022-1042
# (`install-dirs`, a prerequisite of install-data-hook) runs, on Linux and when
# DESTDIR is empty, `systemd-sysusers` or groupadd and useradd to create a `tss`
# user and group on the HOST, and creates and chowns state directories. Both are
# skipped when DESTDIR is set (:920-937 `test -z "${DESTDIR}"`, :1025
# `test -n "$(DESTDIR)"`), so the install is staged and copied into the prefix.
# The udev rules (:207) are installed under the prefix by --with-udevrulesdir.

summary = "tpm2-tss: TCG TPM2 software stack (ESAPI, SAPI, MU, RC and TCTI libraries)"

# LICENSE:1-22 is the BSD 2-Clause text (two conditions, "AS IS" disclaimer).
license = "BSD-2-Clause"

platforms = ["linux"]

versions {
  # Tags are `4.2.2`; `4.2.2-rc0` is a pre-release, `4.2.2s` and
  # `andreas-fuchs-pub` are signed-tag and key tags.
  github = "tpm2-software/tpm2-tss/tags"
  ignore = ["/rc|s$|pub/"]
}

dependencies = {
  # configure.ac:171-177: libcrypto >= 1.1.0 through pkg-config; tss2-esys.pc
  # lists the crypto libraries in Libs.private.
  "openssl.org" = "^3"
}

distributable {
  # The SIGNED release tarball (tpm2-tss-4.2.2.tar.gz.asc beside it): it carries
  # the generated configure that the GitHub tag archive does not.
  url              = "https://github.com/tpm2-software/tpm2-tss/releases/download/{{version.raw}}/tpm2-tss-{{version.raw}}.tar.gz"
  strip-components = 1

  # 4.2.2: 1937061 bytes. Recorded with `zpkb sourcepin --sig auto` (signature
  # verified, see provenance.note).
  sha256 = {
    "4.2.2" = "bd4efc89ee01aca8ff771cae268d84333b7594c2d4afee50bb13b859f1113c3f"
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
      "--sysconfdir={{prefix}}/etc",
      "--localstatedir={{prefix}}/var",
      "--with-runstatedir={{prefix}}/run",

      # :114-119 default yes; :149-152 the OpenSSL backend is the default.
      "--enable-esys",
      "--with-crypto=ossl",

      "--disable-fapi",
      "--disable-policy",
      "--disable-tcti-libtpms",
      "--disable-tcti-spi-ltt2go",
      "--disable-tcti-spi-ftdi",
      "--disable-tcti-i2c-ftdi",
      "--disable-tcti-spidev",
      "--disable-doxygen-doc",

      # The plain TCTI modules (:239-293), default yes; stated.
      "--enable-tcti-device",
      "--enable-tcti-mssim",
      "--enable-tcti-swtpm",
      "--enable-tcti-pcap",
      "--enable-tcti-null",
      "--enable-tcti-cmd",

      # :396-403 default no: the TCTIs are dlopen'd, as systemd expects.
      "--disable-nodl",

      # The udev rules go inside the prefix (Makefile.am:207); sysusers.d and
      # tmpfiles.d are not wanted (:88-98, the conditions at Makefile.am:718-723
      # compare against `no`).
      "--with-udevrulesdir={{prefix}}/lib/udev/rules.d",
      "--with-sysusersdir=no",
      "--with-tmpfilesdir=no",

      "--disable-static",
    ]

    PKG_CONFIG_PATH = "{{deps.openssl.org.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib64/pkgconfig"

    # ESYS dlopen's the TCTI libraries (libtss2-tcti-device.so.0, ...) and links
    # libcrypto: the library directories are also run-time rpaths. -z now, relro
    # and noexecstack are added by the project itself (configure.ac:629-632).
    LDFLAGS = "-L{{deps.openssl.org.prefix}}/lib -L{{deps.openssl.org.prefix}}/lib64 -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib64"
    CPPFLAGS = "-I{{deps.openssl.org.prefix}}/include"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",

    # Staged: with DESTDIR set the install does not touch the host's users and
    # state directories (see the header).
    "make install DESTDIR=\"$PWD/stage\"",
    "cp -a \"$PWD/stage{{prefix}}/.\" \"{{prefix}}/\"",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/include/tss2/tss2_esys.h\"",
    "test -f \"{{prefix}}/include/tss2/tss2_rc.h\"",
    "test -f \"{{prefix}}/include/tss2/tss2_mu.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/tss2-esys.pc\"",
    "test -f \"{{prefix}}/lib/pkgconfig/tss2-rc.pc\"",
    "test -f \"{{prefix}}/lib/pkgconfig/tss2-mu.pc\"",
    "test -f \"{{prefix}}/lib/pkgconfig/tss2-tcti-device.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/tss2-esys.pc\"",
    "test -e \"{{prefix}}/lib/libtss2-esys.so\"",
    "test -e \"{{prefix}}/lib/libtss2-rc.so\"",
    "test -e \"{{prefix}}/lib/libtss2-mu.so\"",
    "test -e \"{{prefix}}/lib/libtss2-tcti-device.so\"",
  ]
}

provenance {
  read = [
    "configure.ac",         # :114-119 esys; :123-129 fapi; :141-147 policy; :149-205 crypto; :207-215 json-c, curl, uuid; :239-394 the TCTIs; :396-403 nodl; :408-416 udev; :581-633 log and flags; :656-670 install helpers; :675 doxygen
    "Makefile.am",          # :207 udev rules; :718-723 sysusers and tmpfiles; :920-937 the tss user; :1022-1052 install-dirs and install-data-hook
    "lib/tss2-esys.pc.in",  # Requires.private tss2-mu tss2-sys
    "LICENSE",              # :1-22 BSD 2-Clause
    "https://github.com/tpm2-software/tpm2-tss (git ls-remote --tags)",
  ]

  consulted = []

  note = <<EOT
  signature  https://github.com/tpm2-software/tpm2-tss/releases/download/4.2.2/tpm2-tss-4.2.2.tar.gz.asc
  signer     DF46949295D2AA0F3479BF4A965B305B2BFAB54E (ed25519, created
             2026-10-26), signed 2026-11-12T08:47:33Z
  identity   Moritz Buhl <moritz.buhl@infineon.com>
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto --key
             <file> --fingerprint DF469492…B54E` against that file.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. The signature's own issuer
fingerprint was used, and the trust placed in it rests on the key's user ID and
the keyserver's copy. The repository does carry tags `andreas-fuchs-pub` and
`juergen-repp-pub` (older maintainers' keys); neither is the signer of 4.2.2,
and no tag for this key was found. A second witness would be a project-
published key.

⛔ NOT BUILT. Unverified: that `--with-sysusersdir=no` and `--with-tmpfilesdir=no`
make SYSD_SYSUSERS and SYSD_TMPFILES false (read at Makefile.am:718-723 and
configure.ac:657, :659, not run); that the staged install copies cleanly into
the prefix (libtool relinks with DESTDIR); that every library name in the test
is installed unversioned as .so; and that the `ignore` pattern drops 4.2.2s
and 4.2.2-rc0 and keeps 4.2.2.
EOT
}
