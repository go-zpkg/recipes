# github.com/p11-glue/p11-kit — loads and shares PKCS#11 modules, and carries
# the "trust" module gnutls reads the system CA store through. Step 2 of
# go-zpkg/recipes#348 (design go-zpkg/packages#440): libtasn1 -> p11-kit ->
# gnutls.
#
# ⛔ WRITTEN FROM P11-KIT'S OWN FILES, at 0.26.6 (the latest release on
# github.com/p11-glue/p11-kit).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established
# is the inputs, each traced to a line in p11-kit's own files.

summary = "p11-kit: PKCS#11 module loader, proxy and trust module"

# COPYING:1-27 is the BSD three-clause text: source and binary redistribution
# conditions, and "The names of contributors … may not be used to endorse".
license = "BSD-3-Clause"

versions {
  # Tags are plain `0.26.6`.
  github = "p11-glue/p11-kit"
}

distributable {
  # The SIGNED release tarball (with .tar.xz.sig beside it), not the generated
  # tag archive: it carries configure, meson.build and the subprojects.
  url              = "https://github.com/p11-glue/p11-kit/releases/download/{{version.raw}}/p11-kit-{{version.raw}}.tar.xz"
  strip-components = 1

  # 0.26.6: 1150004 bytes. Recorded with `zpkb sourcepin --sig auto`
  # (signature verified, see provenance.note) and confirmed by an independent
  # `shasum -a 256` of the same file.
  sha256 = {
    "0.26.6" = "5fda95dc89964af32dbd8e01b139c166717cf96c4fee3d601bcd60bdb23d23c6"
  }
}

build {
  dependencies = {
    "mesonbuild.com"             = "*"
    "ninja-build.org"            = "*"
    "freedesktop.org/pkg-config" = "*"
    "python.org"                 = "^3"
    "gnu.org/gcc"                = "*"

    "gnu.org/libtasn1"     = "4"
    "sourceware.org/libffi" = "3"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir={{prefix}}/lib",
      "--buildtype=release",

      # meson.build:482 `subproject('pkcs11-json')`: the directory ships in the
      # tarball (subprojects/pkcs11-json), so no download is ever needed.
      "--wrap-mode=nofallback",

      # meson_options.txt:25 libffi (feature, auto): meson.build:378 needs
      # `>= 3.0.0`. Named ON so a missing libffi is an error, not a silent
      # fallback to the precompiled closures (:384-387).
      "-Dlibffi=enabled",

      # meson_options.txt:33 trust_module (feature, auto): meson.build:440-449
      # builds it only when libtasn1 and asn1Parser are both found. ON, which
      # turns a missing one into an error: gnutls reads the CA store through it.
      "-Dtrust_module=enabled",

      # meson_options.txt:45 systemd (feature, auto): meson.build:461 asks for
      # the `systemd` pkg-config module. systemd.io depends on this recipe once
      # gnutls is on, so enabling it here would be a dependency cycle. OFF.
      "-Dsystemd=disabled",

      # meson_options.txt:57 and :65: shell completion files; auto otherwise.
      "-Dbash_completion=disabled",
      "-Dzsh_completion=disabled",

      # meson_options.txt:69 gtk_doc and :77 man (xsltproc): documentation
      # toolchains this recipe does not declare. Both default false; stated.
      "-Dgtk_doc=false",
      "-Dman=false",

      # meson_options.txt:81 nls (default true): meson.build:492 builds po/,
      # which needs the msgfmt tool; no gettext tool is declared here. OFF.
      "-Dnls=false",

      # meson_options.txt:85 test (default true): builds the test programs
      # and the -testable twins (p11-kit/meson.build:251-259). Not installed;
      # OFF to keep the build lean.
      "-Dtest=false",

      # meson_options.txt:37 trust_paths is left empty (its default): the
      # system CA bundle location belongs to whoever packages a bundle, and no
      # such recipe is declared here.
    ]

    PKG_CONFIG_PATH = "{{deps.gnu.org/libtasn1.prefix}}/lib/pkgconfig:{{deps.sourceware.org/libffi.prefix}}/lib/pkgconfig:{{deps.sourceware.org/libffi.prefix}}/lib64/pkgconfig"
    LDFLAGS         = "-Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.gnu.org/libtasn1.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/libffi.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/libffi.prefix}}/lib64"
    # meson.build:443 find_program('asn1Parser'): it must be on PATH.
    PATH            = "{{deps.gnu.org/libtasn1.prefix}}/bin:$PATH"
  }

  script = [
    "meson setup build $ARGS",
    "meson compile -C build",
    "meson install -C build",
  ]
}

# p11-kit/meson.build:244 `executable('p11-kit', … install: true)`; the
# trust/ directory builds `trust` (trust/meson.build:73). Both install to bin.
provides = [
  "bin/p11-kit",
  "bin/trust",
]

test {
  script = [
    "test -x \"{{prefix}}/bin/p11-kit\"",
    "test -x \"{{prefix}}/bin/trust\"",
    # p11-kit/meson.build:521-526: filebase `p11-kit-1`, subdirs `p11-kit-1`.
    "test -f \"{{prefix}}/lib/pkgconfig/p11-kit-1.pc\"",
    "test -d \"{{prefix}}/include/p11-kit-1/p11-kit\"",
    # meson.build:406-408 module_path defaults to <libdir>/pkcs11, which is
    # where the trust module is installed.
    "test -f \"{{prefix}}/lib/pkcs11/p11-kit-trust.so\"",
    "\"{{prefix}}/bin/p11-kit\" --help >/dev/null 2>&1 || test $? -le 1",
  ]
}

provenance {
  read = [
    "meson.build",             # :378 libffi; :394-413 config and module directories; :437-450 trust module and libtasn1; :458-468 systemd; :482 pkcs11-json subproject; :492 nls
    "meson_options.txt",       # every option named in the build block
    "p11-kit/meson.build",     # :244 p11-kit; :261 remote; :277 server; :521-526 the .pc file
    "trust/meson.build",       # :73 the trust program
    "COPYING",                 # :1-27 the BSD three-clause text
    "README",                  # :33 the maintainers whose keys sign releases
    "https://github.com/p11-glue/p11-kit/releases", # the release and its .sig
  ]

  consulted = []

  note = <<EOT
  signature  https://github.com/p11-glue/p11-kit/releases/download/0.26.6/p11-kit-0.26.6.tar.xz.sig
  signer     5D46CB0F763405A7053556F47A75A648B3F9220C (Ed25519),
             signed 2026-11-12
  identity   Zoltan Fridrich <zfridric@redhat.com>
  fingerprint came from: p11-kit-0.26.6 README:33, which lists two maintainers
             ("Daiki Ueno", "Zoltan Fridrich") and links this fingerprint
  key from   https://gnutls.org/gnutls-release-keyring.gpg (the gnutls
             project's release keyring, which holds the same fingerprint)

The fingerprint comes from the project's own README, shipped inside the
tarball it names — so its warrant is the tarball itself, and the keyring
that supplied the key bytes is a second host of the same maintainer's key.
That is continuity, not independence. No keyserver was asked.

⛔ NOT BUILT. Unverified: that the `systemd` option disabled here leaves
nothing else asking for a systemd.pc; that `PATH` is honoured in `env`; and
that `meson install` places the trust module under lib/pkcs11.
EOT
}
