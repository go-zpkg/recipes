# github.com/cracklib/cracklib — libcrack, the password strength checking library
# and its dictionary tools. Batch 3 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): libpwquality (next recipe) needs libcrack, and
# systemd's `pwquality` option (meson_options.txt:442) needs libpwquality.
#
# ⛔ WRITTEN FROM CRACKLIB'S OWN FILES (configure.ac, util/Makefile.am,
# dicts/Makefile.am) at 2.10.4. NOT BUILT: builds are suspended by a security
# hold; what is established is the inputs.
#
# WHAT IS ON. libcrack, cracklib-packer/-unpacker/-check and the installed
# `cracklib-small` word list (dicts/Makefile.am:1, pkgdatadir).
# WHAT IS OFF, with the reason:
#   --without-python (configure.ac:74-97): the default is `auto` and would build a
#       Python module with whatever interpreter the host has.
#   --disable-nls (:54-62, AM_GNU_GETTEXT([external])): gettext would otherwise be
#       taken from the host.
#   --without-zlib is NOT passed: zlib is probed (:21-31) and is declared, so the
#       library reads gzip word lists.
# The default dictionary path is the project's own `$(pkgdatadir)/pw_dict`
# (:66-69), inside the prefix; the `pw_dict` itself is built from a word list with
# `cracklib-packer` (a user step, util/create-cracklib-dict) and is not shipped.

summary = "cracklib: password strength checking library and dictionary tools"

license = "LGPL-2.1-or-later"

platforms = ["linux"]

versions {
  # Tags are `v2.10.4`; `v2.10.4-gpg` and `v2.7-3.0pre*` are not releases.
  github = "cracklib/cracklib/tags"
  strip  = ["/^v/"]
  ignore = ["/gpg|pre/"]
}

dependencies = {
  "zlib.net" = "*"
}

distributable {
  # The SIGNED release tarball (.asc beside it), generated configure included.
  url              = "https://github.com/cracklib/cracklib/releases/download/v{{version.raw}}/cracklib-{{version.raw}}.tar.xz"
  strip-components = 1

  sha256 = {
    "2.10.4" = "503573391cfea3e1fca0b7ea0011c887f87f49cf2a97db9a54f92094e604b82b"
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
      "--without-python",
      "--disable-nls",
      "--disable-static",
    ]
    CPPFLAGS = "-I{{deps.zlib.net.prefix}}/include"
    LDFLAGS  = "-L{{deps.zlib.net.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.zlib.net.prefix}}/lib"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

provides = [
  "sbin/cracklib-packer",
  "sbin/cracklib-check",
]

test {
  script = [
    "test -x \"{{prefix}}/sbin/cracklib-packer\"",
    "test -f \"{{prefix}}/include/crack.h\"",
    "test -e \"{{prefix}}/lib/libcrack.so\"",
    "test -f \"{{prefix}}/share/cracklib/cracklib-small\"",
  ]
}

provenance {
  read = [
    "configure.ac",         # :21-31 zlib; :54-62 gettext; :66-71 default dict; :74-97 python
    "util/Makefile.am",     # :1 sbin programs, :11 scripts
    "dicts/Makefile.am",    # :1 the installed word list
  ]

  consulted = []

  note = <<EOT
  signature  https://github.com/cracklib/cracklib/releases/download/v2.10.4/cracklib-2.10.4.tar.xz.asc
  signer     FCE0F8C65F5B2972C2EB55E2350D0B0705E9C3CB
  identity   Nathan Neulinger
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto`.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. The signature's own issuer
fingerprint was used; trust rests on the key carrying the maintainer's user ID
as the keyserver holds it.

⛔ NOT BUILT. Unverified: that `--without-python` and `--disable-nls` are
accepted verbatim (read from configure.ac, not run); that libcrack.so and
crack.h land at the paths the test names (from lib/Makefile.am, not read).
EOT
}
