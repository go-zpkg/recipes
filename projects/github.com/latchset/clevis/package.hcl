# github.com/latchset/clevis — pluggable framework for automated decryption:
# `clevis encrypt <pin> <config>` binds a secret to a policy (null, sss =
# Shamir secret sharing, tang, tpm2) and `clevis decrypt` recovers it;
# `clevis luks bind|unlock|list|...` binds a LUKS volume's key slot to a pin.
#
# ⛔ WRITTEN FROM CLEVIS' OWN FILES (meson.build, meson_options.txt,
# src/luks/meson.build, src/pins/tpm2/meson.build) at v25, the newest release
# (GitHub `releases/latest`). The release tarball is used (.tar.xz). The digest is
# computed from my own download.
#
# WHAT IS BUILT. `jose` (the recipe beside this) does every key and JWE.
# libcryptsetup and luksmeta present at configure time turn the LUKS bindings on;
# without them meson warns and installs none, so both are build inputs. The
# tpm2 pin is installed only if the tpm2_* tools are in PATH at configure time,
# so tpm2-tools is a build input too, and a run-time one for that pin.
# The man pages are built only if a2x is found (no option; asciidoc has no
# recipe, so none). `-Dtpm1=disabled` and `-Dpkcs11=disabled` (features; their
# tools have no recipe, stated so a host's cannot leak in); `-Duser`/`-Dgroup` are
# left to meson_options.txt's defaults (the `clevis` system user is only used by
# the udisks2/dracut/systemd integrations, not built here).
#
# NOT TESTED: the tang pin (needs a tang server), the tpm2 pin's actual use (no
# TPM), `clevis luks unlock` (needs device-mapper and root).
# jq is used by clevis-luks-edit and by upstream's own tests; no jq recipe exists.

summary = "clevis: pluggable framework for automated decryption (null, sss, tang, tpm2 pins; LUKS binding)"

license = "GPL-3.0-or-later"

platforms = ["linux"]

versions {
  # Tags are `v25`.
  github = "latchset/clevis"
}

dependencies = {
  "github.com/latchset/jose"         = "15"
  "github.com/latchset/luksmeta"     = "11"
  "gitlab.com/cryptsetup/cryptsetup" = "^2"
  "github.com/tpm2-software/tpm2-tools" = "5"
  "gnu.org/bash"                     = "*"
  "gnu.org/coreutils"                = "*"
}

distributable {
  url              = "https://github.com/latchset/clevis/releases/download/v{{version.raw}}/clevis-{{version.raw}}.tar.xz"
  strip-components = 1

  # 25, computed from my own download.
  sha256 = {
    "25" = "14c07dbdedec9d32896a50cfda6862d4853f51ac069f30708470954956a3929f"
  }
}

build {
  dependencies = {
    "mesonbuild.com"             = "*"
    "ninja-build.org"            = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir=lib",
      "--buildtype=release",
      "-Dtpm1=disabled",
      "-Dpkcs11=disabled",
    ]

    PKG_CONFIG_PATH = "{{deps.github.com/latchset/jose.prefix}}/lib/pkgconfig:{{deps.github.com/latchset/luksmeta.prefix}}/lib/pkgconfig:{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib/pkgconfig"

    # clevis' pins find tpm2_* and jose in PATH at configure time.
    PATH = "{{deps.github.com/tpm2-software/tpm2-tools.prefix}}/bin:{{deps.github.com/latchset/jose.prefix}}/bin:$PATH"

    LDFLAGS = "-L{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.github.com/latchset/jose.prefix}}/lib -Wl,-rpath,{{deps.github.com/latchset/luksmeta.prefix}}/lib -Wl,-rpath,{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib"
  }

  script = [
    "meson setup build $ARGS",
    "meson compile -C build",
    "meson install -C build",
  ]
}

provides = [
  "bin/clevis",
  "bin/clevis-encrypt-tpm2",
]

test {
  dependencies = {
    "gitlab.com/cryptsetup/cryptsetup" = "^2"
  }

  script = [
    "test -x {{prefix}}/bin/clevis",
    # The tpm2 pin was built: tpm2-tools was in PATH at configure time.
    "test -x {{prefix}}/bin/clevis-encrypt-tpm2",
    # null pin: round trip.
    "printf hello > msg",
    "clevis encrypt null '{}' < msg > null.jwe",
    "clevis decrypt < null.jwe > null.out",
    "cmp msg null.out",
    # sss: 2 of 2 null pins, then 1 of 1.
    "clevis encrypt sss '{\"t\":2,\"pins\":{\"null\":[{},{}]}}' < msg > sss2.jwe",
    "clevis decrypt < sss2.jwe > sss2.out",
    "cmp msg sss2.out",
    "clevis encrypt sss '{\"t\":1,\"pins\":{\"null\":[{}]}}' < msg > sss1.jwe",
    "clevis decrypt < sss1.jwe > sss1.out",
    "cmp msg sss1.out",
    # LUKS: bind a LUKS1 header in a regular file (no device-mapper needed).
    "truncate -s 8M luks.img",
    "printf foo | cryptsetup luksFormat --type luks1 --batch-mode --pbkdf pbkdf2 --pbkdf-force-iterations 1000 luks.img -",
    "printf foo | clevis luks bind -f -d luks.img -k - sss '{\"t\":1,\"pins\":{\"null\":[{}]}}'",
    "clevis luks list -d luks.img > list.out",
    "grep -q ' sss ' list.out",
    "luksmeta show -d luks.img > meta.out",
    "grep -Eq '^1 +active [0-9a-f]{8}-' meta.out",
  ]
}

provenance {
  read = [
    "meson.build",
    "meson_options.txt",
    "src/luks/meson.build",
    "src/pins/tpm2/meson.build",  # :119-135 the tpm2_* programs that make the pin build
    "https://github.com/latchset/clevis/releases",
  ]

  consulted = []

  note = <<EOT
Built and run on Linux (aarch64, glibc) with the commands of this file, against
the container's libraries and jose, luksmeta and tpm2-tools built from the sibling
recipes' flags; every test line passed there (including the LUKS1 sss bind, list
and the luksmeta UUID).

⚠ `clevis luks unbind` prints "Nothing to read on input." when run with -f and
no stdin; it still unbinds. Not in the test.
⚠ jq has no recipe: `clevis luks edit` (and upstream's test suite) need it at run time.
EOT
}
