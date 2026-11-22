# github.com/libpwquality/libpwquality — password quality checking library, the
# pam_pwquality module and pwscore/pwmake. Batch 3 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): systemd's `pwquality` option (meson_options.txt:442) lets
# homed/homectl check new passwords with libpwquality.
#
# ⛔ WRITTEN FROM LIBPWQUALITY'S OWN configure.ac at 1.4.5. NOT BUILT: builds are
# suspended by a security hold; what is established is the inputs.
#
# WHAT IS ON. The library, pwscore, pwmake, and pam_pwquality (--enable-pam,
# configure.ac:87-111; stated, because the default `check` follows whatever
# libpam the link path finds). cracklib dictionary checks stay ON (:161-178): the
# probe is AC_CHECK_LIB(crack) with no pkg-config, so the cracklib prefix is
# given by CPPFLAGS and LDFLAGS.
# WHAT IS OFF, with the reason:
#   --disable-python-bindings (:124-152): default ON; it runs the host's
#       `python` to find its version and installs into a python site directory.
#   --disable-nls: gettext is host-taken otherwise (po/ and ABOUT-NLS ship).
# The PAM module lands in {{prefix}}/lib/security (--with-securedir, :114-117 the
# default is $libdir/security, stated) and its config in {{prefix}}/etc/security
# (:119-122, $sysconfdir/security), both inside the prefix.

summary = "libpwquality: password quality checking library with pam_pwquality"

# COPYING: BSD-3-Clause OR GPL-2.0-or-later, as the source headers say.
license = "BSD-3-Clause OR GPL-2.0-or-later"

platforms = ["linux"]

versions {
  # Tags are `libpwquality-1.4.5`.
  github = "libpwquality/libpwquality/tags"
  strip  = ["/^libpwquality-/"]
}

dependencies = {
  "github.com/cracklib/cracklib"     = "*"
  "github.com/linux-pam/linux-pam"   = "*"
}

distributable {
  # The release tarball (generated configure included). NO signature is
  # published: libpwquality-1.4.5.tar.bz2.asc and .sig both answer 404.
  url              = "https://github.com/libpwquality/libpwquality/releases/download/libpwquality-{{version.raw}}/libpwquality-{{version.raw}}.tar.bz2"
  strip-components = 1

  # 1.4.5. UNSIGNED: the pin below is the digest of the downloaded file, checked
  # by an independent second download (see provenance.note).
  sha256 = {
    "1.4.5" = "6fcf18b75d305d99d04d2e42982ed5b787a081af2842220ed63287a2d6a10988"
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
      "--enable-pam",
      "--with-securedir={{prefix}}/lib/security",
      "--disable-python-bindings",
      "--disable-nls",
      "--disable-static",
    ]
    CPPFLAGS = "-I{{deps.github.com/cracklib/cracklib.prefix}}/include -I{{deps.github.com/linux-pam/linux-pam.prefix}}/include"
    LDFLAGS  = "-L{{deps.github.com/cracklib/cracklib.prefix}}/lib -L{{deps.github.com/linux-pam/linux-pam.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.github.com/cracklib/cracklib.prefix}}/lib -Wl,-rpath,{{deps.github.com/linux-pam/linux-pam.prefix}}/lib"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

provides = [
  "bin/pwscore",
  "bin/pwmake",
]

test {
  script = [
    "test -x \"{{prefix}}/bin/pwscore\"",
    "test -f \"{{prefix}}/include/pwquality.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/pwquality.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/pwquality.pc\"",
    "test -f \"{{prefix}}/lib/security/pam_pwquality.so\"",
  ]
}

provenance {
  read = [
    "configure.ac",  # :87-111 pam; :114-122 securedir, sconfigdir; :124-152 python; :161-178 cracklib
  ]

  consulted = []

  note = <<EOT
⚠ UNSIGNED. No signature or checksum is published by the project. The sha256 is
the digest of the release tarball as downloaded, confirmed by a second download.

⛔ NOT BUILT. The pc file (pwquality.pc), the header (pwquality.h) and the
programs (pwscore, pwmake) are read from src/Makefile.am:13-15,60-63. Unverified: that
--disable-python-bindings is accepted verbatim (read from configure.ac:124-129);
that pam_pwquality links against the declared linux-pam prefix rather than a host libpam.
EOT
}
