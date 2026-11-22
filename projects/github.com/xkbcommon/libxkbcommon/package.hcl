# github.com/xkbcommon/libxkbcommon — libxkbcommon: the keyboard keymap
# compiler and state machine. Step 3 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): systemd's `xkbcommon` option (meson_options.txt:488) lets
# is used by src/locale/localed-util.c, src/locale/xkbcommon-util.c and
# src/shared/vconsole-util.c (meson.build:1444, `dependency('xkbcommon')`).
#
# ⛔ WRITTEN FROM LIBXKBCOMMON'S OWN FILES (meson.build, meson_options.txt) at
# 1.13.2 — the newest STABLE tag: `git ls-remote --tags` lists
# xkbcommon-1.13.2 after 1.13.1 and 1.13.0, read in version order; the tags
# above it, 1.14.0-beta1 and 1.14.0-beta2, are pre-releases and are ignored.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# THE DATA IS A RUN-TIME DEPENDENCY, FOUND AT BUILD TIME. meson.build:75-121 asks
# pkg-config for `xkeyboard-config-N` (N from 12 down to 2, :83-101) and compiles
# its `xkb_root` variable in as the XKB config root, with the extension paths
# derived from it (:123-150). So freedesktop.org/xkeyboard-config is declared as
# a dependency, its share/pkgconfig is on PKG_CONFIG_PATH (⛔ share, not lib: that
# recipe says why), and the root is also STATED with `-Dxkb-config-root`, so that
# a missing .pc cannot silently fall back to the legacy /usr/share/X11/xkb
# (meson.build:59-73, :118-119).
#
# OPTIONS (meson_options.txt), every one that detects or chooses:
#   enable-tools (:61) default true: the `xkbcli` programs; systemd needs only
#       the library, and the tools pick up optional ICU (meson.build:609,
#       `dependency('icu-uc', required: false)`, a host leak) and the Wayland and
#       X11 programs. OFF.
#   enable-x11 (:67) default true: libxkbcommon-x11 needs xcb-xkb
#       (meson.build:457-462, an ERROR when absent). systemd does not use it. OFF.
#   enable-wayland (:85) default true: needs wayland-client and wayland-protocols
#       (meson.build:752-758, an error when absent). OFF.
#   enable-xkbregistry (:91) default true: libxkbregistry needs libxml2
#       (meson.build:531-533). systemd does not use it. OFF.
#   enable-docs (:73) default false (doxygen); enable-cool-uris (:79),
#       enable-bash-completion (:97): all stated off.
#   default-rules (:31) evdev, default-model (:37) pc105, default-layout (:43) us,
#       default-variant (:49), default-options (:55): upstream defaults, stated.
#   ICU, still: line 973 adds icu-uc to the KEYSYM TEST dependencies when found,
#       tests only; the tools that would install against it are off.
# BUILD REQUIREMENTS: meson >= 1.4.0 (meson.build:9), bison >= 3.6 (:320, the
# parser is generated from src/xkbcomp/parser.y).
# Directories: --sysconfdir=etc keeps the extra lookup path (:152-155,
# `prefix/sysconfdir/xkb`) inside the prefix; nothing is installed there.

summary = "libxkbcommon: keyboard keymap compiler and state library"

# LICENSE:16-175 lists the statements for the code of the shared library: MIT,
# MIT-open-group, HPND, HPND-sell-variant and a Digital Equipment Corporation
# notice (LicenseRef). The test-data statements after :178 are not distributed.
license = "MIT AND MIT-open-group AND HPND AND HPND-sell-variant AND LicenseRef-digital-equipment-corporation"

platforms = ["linux", "darwin"]

versions {
  # Tags are `xkbcommon-1.13.2`; 1.14.0-beta1 is a pre-release.
  github = "xkbcommon/libxkbcommon/tags"
  strip  = ["/^xkbcommon-/"]
  ignore = ["/beta|alpha|rc/"]
}

dependencies = {
  # The database the library compiles keymaps from (see the header).
  "freedesktop.org/xkeyboard-config" = "2"
}

distributable {
  # ⚠ A GENERATED ARCHIVE. The GitHub release of xkbcommon-1.13.2 carries no
  # uploaded asset (HTTP 404 on releases/download/…/libxkbcommon-1.13.2.tar.xz) and
  # xkbcommon.org/download/ answers 404, so there is no signed tarball to pin.
  url              = "https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-{{version.raw}}.tar.gz"
  strip-components = 1

  # 1243485 bytes, recorded with `zpkb sourcepin --version 1.13.2` and reproduced
  # by an independent curl-and-shasum (acc4d5f7…385528).
  sha256 = {
    "1.13.2" = "acc4d5f7c3cbba5f9f8d08d8bdbeede84ecede46792f47929aa9321873385528"
  }
}

build {
  dependencies = {
    "mesonbuild.com"             = "*"
    "ninja-build.org"            = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/bison"              = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir={{prefix}}/lib",
      "--sysconfdir=etc",
      "--buildtype=release",
      "--wrap-mode=nofallback",

      "-Dxkb-config-root={{deps.freedesktop.org/xkeyboard-config.prefix}}/share/xkeyboard-config-2",

      "-Denable-tools=false",
      "-Denable-x11=false",
      "-Denable-wayland=false",
      "-Denable-xkbregistry=false",
      "-Denable-docs=false",
      "-Denable-cool-uris=false",
      "-Denable-bash-completion=false",

      "-Ddefault-rules=evdev",
      "-Ddefault-model=pc105",
      "-Ddefault-layout=us",
    ]

    PKG_CONFIG_PATH = "{{deps.freedesktop.org/xkeyboard-config.prefix}}/share/pkgconfig"
  }

  script = [
    "meson setup build $ARGS",
    "meson compile -C build",
    "meson install -C build",
  ]
}

test {
  dependencies = {
    "gnu.org/gcc"                = "*"
    "freedesktop.org/pkg-config" = "*"
  }

  script = [
    "test -f \"{{prefix}}/include/xkbcommon/xkbcommon.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/xkbcommon.pc\"",
    "pkg-config --exists xkbcommon",
    {
      fixture = {
        content  = <<EOT
#include <xkbcommon/xkbcommon.h>
#include <stdio.h>

int main(void) {
  struct xkb_context *ctx = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
  struct xkb_keymap *map;
  if (ctx == NULL) {
    puts("xkb_context_new failed");
    return 1;
  }
  /* NULL names = the compiled-in defaults (evdev, pc105, us): this fails
     if the xkeyboard-config root was not found. */
  map = xkb_keymap_new_from_names(ctx, NULL, XKB_KEYMAP_COMPILE_NO_FLAGS);
  if (map == NULL) {
    puts("the default keymap did not compile: no xkeyboard-config data");
    return 1;
  }
  puts("default keymap compiled");
  xkb_keymap_unref(map);
  xkb_context_unref(ctx);
  return 0;
}
EOT
        extname = "c"
      }
      run = "gcc $FIXTURE -o xkbtest $(pkg-config --cflags --libs xkbcommon)"
    },
    "./xkbtest",
  ]
}

provenance {
  read = [
    "meson.build",        # :4 version 1.13.2; :9 meson >= 1.4.0; :55-161 the xkeyboard-config lookup and the compiled-in roots; :194-203 the defaults; :320 bison >= 3.6; :457-462 x11; :531-533 xkbregistry; :609 ICU; :752-758 wayland
    "meson_options.txt",  # all 19 options
    "LICENSE",            # :16-175 the statements for the library; :178 onward test data only
    "https://github.com/xkbcommon/libxkbcommon (git ls-remote --tags)",
  ]

  consulted = []

  note = <<EOT
  source     https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-1.13.2.tar.gz
  sha256     acc4d5f7c3cbba5f9f8d08d8bdbeede84ecede46792f47929aa9321873385528

⚠ NO SIGNATURE. No signed tarball exists for 1.13.2 (the release has no asset,
xkbcommon.org/download/ is 404) and the tag was not checked. The digest is a
cross-check: `zpkb sourcepin` and an independent curl plus `shasum -a 256` of
the same URL agree. GitHub regenerates tag archives, so a mismatch means a
changed archive or a moved tag, to be investigated and not re-pinned blindly.

⛔ NOT BUILT. Unverified: that the xkeyboard-config-2.pc `xkb_root` the build
reads equals the `-Dxkb-config-root` stated (both are
<prefix>/share/xkeyboard-config-2); that the fixture's NULL names resolve
to evdev/pc105/us; that the strip of the `xkbcommon-` prefix leaves `1.13.2`
for the versions block (not run).
EOT
}
