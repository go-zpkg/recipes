# skarnet.org/execline — a non-interactive scripting language where a script is
# a chain of commands, each one executing the next (`foreground`, `if`,
# `backtick`, `importas`, `forx`, `pipeline`, ...), plus `execlineb`, the parser
# that turns a script into that chain. s6 and s6-rc are written for it.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 2.10.0.0, the
# newest release on https://skarnet.org/software/execline/ (GitHub mirror tag
# v2.10.0.0). Digest computed from the download.
#
# Read from `./configure --help`: the binaries link the skalibs STATIC archive
# by default (`--disable-allstatic` is the opposite), so nothing is looked up at
# run time; skalibs is a build input, reached with --with-sysdeps, --with-include
# and --with-lib, because it is installed in its own prefix. Shared libraries
# are off by default (--enable-shared) and are not needed by s6. The scripts
# written for `execlineb` start with the absolute path `--shebangdir`, which
# defaults to BINDIR, i.e. this package's own bin directory.

summary = "execline: a scripting language where every command execs into the next"

# COPYING: ISC licence.
license = "ISC"

versions {
  github = "skarnet/execline"
}

dependencies = {
  "skarnet.org/skalibs" = "^2"
}

distributable {
  url              = "https://skarnet.org/software/execline/execline-{{version.raw}}.tar.gz"
  strip-components = 1

  # 2.10.0.0: 118300 bytes, computed from the download.
  sha256 = {
    "2.10.0.0" = "561be2ce578604644e2263a889bbdf4736e7980401ee88556a7f9017c166dbab"
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
      "--enable-pkgconfig",
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

# Read from the install: the language's commands and the parser. Only names
# that the build produced are listed; `if`, `exec` and the other single-word
# commands exist too and are reachable by the full path.
provides = [
  "bin/execlineb",
  "bin/foreground",
  "bin/background",
  "bin/backtick",
  "bin/importas",
  "bin/pipeline",
  "bin/redirfd",
  "bin/fdmove",
  "bin/forx",
  "bin/forstdin",
  "bin/ifelse",
  "bin/ifthenelse",
  "bin/multisubstitute",
]

test {
  script = [
    "test -f {{prefix}}/include/execline/execline.h",
    "test -f {{prefix}}/lib/libexecline.a",
    "test -x {{prefix}}/bin/execlineb",
    # A one-line script given to the parser, run.
    "execlineb -Pc 'foreground { echo one } echo two' > chain.out",
    "grep -qx one chain.out",
    "grep -qx two chain.out",
    # A script file: the shebang names the installed execlineb, a command
    # substitution runs `echo`, and importas reads the variable back. $$ is the
    # HCL spelling of a literal dollar before a brace.
    {
      run = "printf '#!{{prefix}}/bin/execlineb -P\\nbacktick -n X { echo hello }\\nimportas -u V X\\necho got-$${V}\\n' > hello.el && chmod +x hello.el && ./hello.el > hello.out && grep -qx got-hello hello.out"
    },
    # `if` runs the rest only when the test succeeds; `eltest` is its test.
    "execlineb -Pc 'if { eltest 2 -lt 3 } echo yes' > if.out",
    "grep -qx yes if.out",
  ]
}

provenance {
  read = [
    "INSTALL",   # requirements: skalibs; `./configure && make && sudo make install`
    "configure", # the option list printed by --help
    "COPYING",   # ISC
    "https://skarnet.org/software/execline/",
  ]

  consulted = []

  note = <<EOT
Built against a separately installed skalibs and run on macOS (arm64) and Linux
with the commands of this file; the three tests above printed the expected lines.

⚠ No signature or checksum file is published beside the tarball; the digest is
the one computed from the download.
EOT
}
