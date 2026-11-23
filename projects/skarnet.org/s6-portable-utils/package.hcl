# skarnet.org/s6-portable-utils — tiny portable replacements for common
# utilities (s6-echo, s6-cat, s6-ln, s6-sleep, s6-test, s6-seq, s6-touch,
# s6-mkdir, s6-chmod, s6-expr, s6-env, s6-nice, s6-basename, ...) that s6-based
# init scripts use instead of coreutils.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 2.3.1.2, the
# newest release on https://skarnet.org/software/s6-portable-utils/ (GitHub
# mirror tag v2.3.1.2). Digest computed from the download.
#
# Needs only skalibs. The tools link the static archive, so nothing is looked
# up at run time.

summary = "s6-portable-utils: tiny portable versions of echo, cat, ln, sleep, seq, ..."

# COPYING: ISC licence.
license = "ISC"

versions {
  github = "skarnet/s6-portable-utils"
}

dependencies = {
  "skarnet.org/skalibs" = "^2"
}

distributable {
  url              = "https://skarnet.org/software/s6-portable-utils/s6-portable-utils-{{version.raw}}.tar.gz"
  strip-components = 1

  # 2.3.1.2: 55999 bytes, computed from the download.
  sha256 = {
    "2.3.1.2" = "cfb90186d0c0eb204e1e5c6f9379e99413c546bccf38bb6e76177f82371aa3aa"
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
  "bin/s6-echo",
  "bin/s6-cat",
  "bin/s6-ln",
  "bin/s6-ls",
  "bin/s6-mkdir",
  "bin/s6-chmod",
  "bin/s6-chown",
  "bin/s6-touch",
  "bin/s6-sleep",
  "bin/s6-seq",
  "bin/s6-expr",
  "bin/s6-env",
  "bin/s6-true",
  "bin/s6-false",
  "bin/s6-head",
  "bin/s6-tail",
  "bin/s6-sort",
  "bin/s6-basename",
  "bin/s6-dirname",
  "bin/s6-grep",
  "bin/s6-nice",
  "bin/s6-rename",
  "bin/s6-rmrf",
  "bin/s6-sync",
]

test {
  script = [
    "test -x {{prefix}}/bin/s6-echo",
    "s6-echo hello > echo.out",
    "grep -qx hello echo.out",
    "s6-seq 1 3 > seq.out",
    "grep -qx 3 seq.out",
    "s6-mkdir -p d/e && s6-touch d/e/f && test -f d/e/f",
    "s6-ln -s f d/e/g && test \"$(s6-linkname d/e/g)\" = f",
    "s6-basename /a/b/c > base.out",
    "grep -qx c base.out",
    "s6-expr 2 + 3 > expr.out",
    "grep -qx 5 expr.out",
    "s6-env FOO=bar s6-env > env.out",
    "grep -qx FOO=bar env.out",
    "s6-sleep -m 10 s6-true",
    "s6-rmrf d && test ! -e d",
  ]
}

provenance {
  read = [
    "INSTALL",   # requirements: skalibs
    "configure", # the option list printed by --help
    "COPYING",   # ISC
    "https://skarnet.org/software/s6-portable-utils/",
  ]

  consulted = []

  note = <<EOT
Built against a separately installed skalibs and run on macOS (arm64) and
Linux; each command used by the test was run once and its output checked.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
