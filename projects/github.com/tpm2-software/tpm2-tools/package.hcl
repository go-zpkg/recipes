# github.com/tpm2-software/tpm2-tools — the command-line tools for a TPM 2.0:
# `tpm2` (one front-end) and about ninety `tpm2_<command>` programs
# (tpm2_createprimary, tpm2_create, tpm2_load, tpm2_unseal, tpm2_pcrread,
# tpm2_startauthsession, tpm2_policypcr, ...), written over tpm2-tss' ESAPI.
#
# It is here for clevis: clevis' meson.build installs the tpm2 pin only if
# `find_program` finds tpm2_createprimary, tpm2_pcrread (or tpm2_pcrlist),
# tpm2_createpolicy, tpm2_create, tpm2_flushcontext, tpm2_load,
# tpm2_startauthsession, tpm2_policypcr and tpm2_unseal at BUILD time
# (src/pins/tpm2/meson.build:119-135), so this package is a build input of
# clevis and a run-time input of its tpm2 pin.
#
# ⛔ WRITTEN FROM TPM2-TOOLS' OWN FILES (configure.ac, README.md) at 5.8, the
# newest release (GitHub `releases/latest`). The release tarball is used, not the
# tag archive: it carries the generated `configure` and the man pages
# (configure.ac:31-33 `test -d man/man1` makes the pages optional on pandoc).
# The digest is computed from my own download.
#
# WHAT IS BUILT. Everything configure.ac makes mandatory, via pkg-config:
# tss2-esys >= 2.4 (:49-68), tss2-tctildr, tss2-mu, tss2-rc, tss2-sys (:72-75),
# libcrypto >= 1.1.0 (:76) and libcurl (:89), all from the tpm2-tss, openssl and
# curl recipes. OFF, with the reason:
#   --disable-fapi (:35-47) is `auto`: it turns the FAPI tools (tss2_*) on if
#       tss2-fapi is found. The tpm2-tss recipe here is built --disable-fapi, so
#       there is none to find; stated, so a host's libtss2-fapi cannot leak in.
#   --disable-unit (:165-169, cmocka at :199) the unit tests need cmocka.
#   efivar (:93-119) is `auto` and prints device paths of boot entries in
#       tpm2_eventlog. `ac_cv_header_efivar_efivar_h=no` answers the header check
#       at :106 so a host with efivar installed cannot leak in; no efivar recipe.
# The bash completion directory is set (:139-143) so configure does not ask
# the build host's bash-completion package through pkg-config.
#
# NOT TESTED AGAINST A TPM. There is no TPM in a build sandbox and no recipe for
# swtpm (which needs libtpms, glib, gnutls, libtasn1 and json-glib); the test
# asserts what runs without one: the error decoder, the dispatcher's help and the
# TCTI loader's refusal of a device that does not exist.

summary = "tpm2-tools: command-line tools for TPM 2.0 (tpm2, tpm2_createprimary, tpm2_unseal, tpm2_pcrread, ...)"

# LICENSE: the BSD 3-Clause text (configure.ac:AC_INIT names it; the file's
# conditions are the three clauses and the disclaimer).
license = "BSD-3-Clause"

platforms = ["linux"]

versions {
  # Tags are `5.8`; release candidates are `5.8-rc0` and similar.
  github = "tpm2-software/tpm2-tools/tags"
  ignore = ["/rc/"]
}

dependencies = {
  "github.com/tpm2-software/tpm2-tss" = "4"
  "openssl.org"                       = "^3"
  "curl.se"                           = "*"
}

distributable {
  # The release tarball (tpm2-tools-5.8.tar.gz.asc beside it).
  url              = "https://github.com/tpm2-software/tpm2-tools/releases/download/{{version.raw}}/tpm2-tools-{{version.raw}}.tar.gz"
  strip-components = 1

  # 5.8, computed from my own download.
  sha256 = {
    "5.8" = "1cb73185cae814b4e15c7c2d0b22642d640faf48775f4156a1fd92edf84bef73"
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
      "--disable-fapi",
      "--disable-unit",
      "--with-bashcompdir={{prefix}}/share/bash-completion/completions",
      "ac_cv_header_efivar_efivar_h=no",
    ]

    PKG_CONFIG_PATH = "{{deps.github.com/tpm2-software/tpm2-tss.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib64/pkgconfig:{{deps.curl.se.prefix}}/lib/pkgconfig"

    # The tools link tss2-* and libcrypto and libcurl; every library directory
    # is also a run-time rpath (the tss2 TCTIs are dlopen'd from tpm2-tss' lib).
    LDFLAGS = "-Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.github.com/tpm2-software/tpm2-tss.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib64 -Wl,-rpath,{{deps.curl.se.prefix}}/lib"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{hw.concurrency}}",
    "make install",
  ]
}

provides = [
  "bin/tpm2",
  "bin/tpm2_createprimary",
  "bin/tpm2_create",
  "bin/tpm2_load",
  "bin/tpm2_unseal",
  "bin/tpm2_pcrread",
  "bin/tpm2_flushcontext",
  "bin/tpm2_startauthsession",
  "bin/tpm2_policypcr",
  "bin/tpm2_createpolicy",
  "bin/tpm2_rc_decode",
  "bin/tpm2_getrandom",
]

test {
  script = [
    "test -x {{prefix}}/bin/tpm2",
    "test -x {{prefix}}/bin/tpm2_unseal",
    # The error decoder is a pure function of its argument: no TPM needed.
    "tpm2_rc_decode 0x100 > rc.out 2>&1",
    "grep -q 'not initialized' rc.out",
    "tpm2_rc_decode 0x9a2 > rc2.out 2>&1",
    "grep -q 'authorization failure' rc2.out",
    # The dispatcher finds and runs a tool's option parser.
    "tpm2 getrandom --help > help.out 2>&1",
    "grep -q '^Usage: getrandom' help.out",
    # The TCTI loader is linked and works: a device that does not exist is
    # refused (a host's own /dev/tpm0 is not consulted: the device is named).
    "if TPM2TOOLS_TCTI=device:/dev/no-such-tpm tpm2_getrandom 4 > /dev/null 2> nodev.err; then exit 1; fi",
    "grep -q 'Could not load tcti' nodev.err",
  ]
}

provenance {
  read = [
    "configure.ac",  # :31-33 man pages; :35-47 fapi; :49-76 the tss2 and crypto modules; :89 curl; :93-119 efivar; :139-143 bashcompdir
    "README.md",     # build and run instructions
    "LICENSE",       # BSD 3-clause
    "https://github.com/tpm2-software/tpm2-tools/releases",
  ]

  consulted = []

  note = <<EOT
Built and run on Linux (aarch64, glibc) with the commands of this file, against
the container's tpm2-tss 4.0.1, openssl and curl; every test line passed there.
Against the pantry's own tpm2-tss 4.2.2 it has not been built: that recipe is
itself marked "NOT BUILT".

SIGNATURE VERIFIED, with a pinned key (2026-11-24), by
`zpkb sourcepin --version 5.8 --sig auto --key <key.asc> --fingerprint
"D533 275B 0123 D0A6 79F5 1FF4 8F4F 9A45 D7FF EE74"`: VALID, made by
D533275B0123D0A679F51FF48F4F9A45D7FFEE74 (Andreas Fuchs
<andreas.fuchs@infineon.com>) on 2026-07-15, against a key file and no
keyserver; the digest it printed is the one above.
  signature  https://github.com/tpm2-software/tpm2-tools/releases/download/5.8/tpm2-tools-5.8.tar.gz.asc
  key        https://keys.openpgp.org/vks/v1/by-fingerprint/D533275B0123D0A679F51FF48F4F9A45D7FFEE74
  fingerprint came from: docs/RELEASE.md INSIDE the 5.8 tarball (the project's
  own table of release signing keys, row `andreas-fuchs-pub`), not from the
  keyserver that served the key file.
The check fails on a tampered file: the same key and signature, run through gpg
in a throwaway keyring, give "Good signature" for the tarball (exit 0) and
"BAD signature" for the tarball with one byte appended (exit 1). At build time
the sha256 above is the durable pin (a changed tarball is refused by the
builder); the signature's job is to justify having WRITTEN that digest.
Re-run the sourcepin command above when bumping the version.

⚠ The `rc` decoder strings in the test come from the TSS error tables of the
tpm2-tss that the tools link; a tpm2-tss that rewords them would fail the test
and not the build.
EOT
}
