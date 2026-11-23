# systemd.io/image — systemd 262.2 installed as a BOOTABLE ROOT FILESYSTEM for a
# container or a microVM (go-zpkg/recipes#348, design section 4).
#
# ⛔ SAME SOURCES AND SAME OPTION SET AS `systemd.io` (projects/systemd.io/
# package.hcl): this file is a copy of that recipe, and every -D option below
# is identical to it EXCEPT the six that make the install an image, listed here.
# When systemd.io gains or drops an option, change this file in the same PR (the
# recipe format has no include; a diff of the two ARGS lists must show only these):
#   --prefix=/usr, --libdir=/usr/lib, --sysconfdir=/etc, --localstatedir=/var
#       the layout systemd hardcodes at run time (/usr/lib/systemd, /etc, /var);
#   -Dpamconfdir=/etc/pam.d, -Ddbus*dir=/usr/share/dbus-1/...  absolute, in the root;
#   -Dcreate-log-dirs=true   installs /var/log/journal, which under DESTDIR lands
#       in the rootfs (src/journal/meson.build:197-198; the store recipe cannot);
#   -Ddefault-network=true   DHCP on every link, what a microVM wants;
#   meson install --destdir {{prefix}}/rootfs, then the layout steps in `script`.
#
# ⛔ NOTHING HERE IS BUILT. `build.rootfs = "rootfs"` (zpkb v0.101.0, go-zpkg/zpkb#538,
# schema/package.schema.json:52; Linux only) opts into zpkb's ROOTFS CLOSURE: every
# ELF under rootfs/ gets its DT_NEEDED libraries (transitively), its PT_INTERP loader
# and its `.note.dlopen` entries resolved against the dependency prefixes and copied
# in. An unresolved DT_NEEDED, a missing loader or a `required` dlopen entry FAILS the
# build. ⛔ THE CLOSURE REWRITES THE STORE RUNPATHs of the copies in place (store
# entries dropped, /usr/lib kept or appended), so the binaries' RUNPATHs are no longer
# the dependency store prefixes that LDFLAGS puts on them at link time.
# Not done in shell. (Closes the TODO of go-zpkg/recipes#348.)
# `provides` below keeps its rootfs/... entries: zpkb ignores non-bin/ provides.
#
# Layout choices, from https://systemd.io/BUILDING_IMAGES/ and
# https://systemd.io/CONTAINER_INTERFACE/ (the latter lists no file the rootfs must
# hold: the manager pre-mounts /proc, /sys, /dev, and /usr is "the only required
# directory to be populated"):
#   - merged /usr: /bin, /sbin, /lib, /lib64 are symlinks into /usr, and
#     /sbin/init = usr/sbin/init -> ../lib/systemd/systemd (split-bin=false);
#   - /usr/lib/os-release is a regular file, /etc/os-release the usual symlink to it;
#   - /etc/machine-id is an EMPTY file: PID 1 then treats the boot as the first
#     one and initialises it (BUILDING_IMAGES also accepts `uninitialized\n`);
#   - nothing shipped that must be unique per instance: no random-seed,
#     credential.secret, /etc/hostname or /etc/machine-info;
#   - empty mount points and tmp dirs, so a read-only root can still boot.
#
# What follows is the header of systemd.io, kept as written.
#
# systemd.io — systemd: the Linux service manager and system daemons
# (`systemctl`, `journalctl`, `udevadm`, `loginctl`, `systemd-analyze` ...).
#
# ⛔ WRITTEN FROM SYSTEMD 262.2'S OWN FILES (go-zpkg/packages#431, #440), read out
# of the tag's source archive, replacing a fragment that named dependencies and
# nothing else. NOT BUILT: this is lint-checked only (see provenance.note).
# Linux only.
#
# ⛔ NOT AN INSTALL FOR A LIVE HOST. Built into a store prefix, the manager,
# udev and the units are INERT there: a system's init is the host's. What the
# recipe provides is the command-line tools and libsystemd/libudev, for
# whatever links or drives them. The sysconfdir is therefore PREFIX-RELATIVE
# (meson.build:133 joins the prefix with `sysconfdir`, whose default `/etc` is
# absolute and would send the install to the host's /etc).
#
# ⛔ THE LOCALSTATEDIR IS NOT. meson.build:136 reads it as
# `localstatedir = '/' / get_option('localstatedir')`, so `--localstatedir=var`
# means the ABSOLUTE `/var`, whatever the prefix. This header used to say both
# were prefix-relative; for localstatedir that was wrong. It is latent, not an
# install escape: localstatedir feeds only compiled-in run-time paths
# (systemdstatedir, randomseeddir, the catalog database) and the one install
# into it, polkitpkladir, happens only when polkit < 0.106 is found
# (src/network/meson.build:284). The only write to /var at install time would
# be create-log-dirs, which stays false below.
#
# ⛔⛔ EVERY OPTION IN meson_options.txt THAT DETECTS OR CHOOSES, STATED. The
# `feature` options are `auto` by default and silently link whatever the
# builder has, so each is named. Booleans keep their documented defaults
# EXCEPT where the default reaches outside the prefix or toward hardware.
#
#   ON, each from a declared recipe:
#     libmount (:498), fdisk (:432), blkid (:430)  util-linux, found as the
#                  `mount`, `fdisk`, `blkid` pkg-config modules (meson.build:
#                  1076, 1086, 1177)
#     seccomp (:405)   kernel.org's libseccomp recipe of this tree (:1113)
#     kmod (:434)      libkmod from kernel.org/kmod of this tree (:1186)
#     libcrypt (:446)  github.com/besser82/libxcrypt (:1046)
#     openssl (:464)   openssl.org (:1297)
#     zlib, bzip2, xz, lz4, zstd (:476-484)   compression of the journal
#     pcre2 (:490)     pcre.org/v2 (:1453)
#     nspawn (:191)    needs no library
#     acl (:426)       savannah.nongnu.org/acl (+ attr), `libacl` (meson.build:1161)
#     libcurl (:452)   curl.se (:1248), which also gates imds (:145) and
#                      importd (:183): meson.build:1564-1575
#     imds (:145), importd (:183)   curl, openssl, zlib, xz, all declared
#     sysupdate (:105) importd, openssl, fdisk (meson.build:1578-1583);
#     sysupdated (:107) = enabled: `auto` is on only in developer mode
#                      (meson.build:1585-1597), `enabled` errors if sysupdate
#                      is off, so it cannot silently drop out
#     repart (:103)    fdisk (meson.build:1550-1552)
#     libidn2 (:456), idn (:454)   gnu.org/libidn2 (:1258)
#     gcrypt (:460)    gnupg.org/libgcrypt (+ libgpg-error) (:1276)
#     polkit (:417)    nothing to build: meson.build:1151-1159 only installs
#                      the policy files (`required : false` on the library)
#     vmspawn (:173) = enabled: `auto` is disabled outside developer mode
#                      (meson.build:1625), stated instead of inherited
#     nss-mymachines (:159), nss-resolve (:161)   glibc only (libc=glibc)
#     efi (:95), tpm (:97)   booleans, no library; the boot LOADER (bootloader,
#                      :501) is a different option and stays off, below
#     smack (:411), ima (:419), ipe (:421)   booleans, no library
#     dns-over-tls (:389) = openssl: one TLS stack, already declared
#     glib (:492), dbus (:494)   "for tests only" (the option's own text): the
#                      unit tests link them, so they follow tests=true
#     tests (:533) = true, dlopen-tests (:535) = true: the unit tests are
#                      BUILT; `unsafe` is NOT chosen, those modify the host
#                      (meson.build:2474). dlopen-tests checks that every
#                      dlopen soname resolves, which is the run-time closure
#                      risk this recipe carries (meson.build:353)
#     gnutls (meson_options.txt:462), p11kit (:466)   gnutls.org and
#                      github.com/p11-glue/p11-kit recipes (go-zpkg/recipes#350);
#                      "+GNUTLS" and "+P11KIT" at src/basic/build.c:67 and :153
#     libcryptsetup (:448), libcryptsetup-plugins (:450)   the
#                      gitlab.com/cryptsetup/cryptsetup recipe (#351);
#                      meson.build:1226-1246 (plugins need libcryptsetup, which
#                      must be >= 2.4.0; this is 2.8.8). They bring
#                      src/cryptsetup, src/cryptenroll, src/veritysetup and
#                      src/integritysetup, each built only when
#                      HAVE_LIBCRYPTSETUP is 1 (their meson.build:3)
#   ON: audit (:428), libarchive (:496), qrencode (:458), from the recipes of
#     go-zpkg/recipes#356: meson.build:1169 `dependency('audit')`, :1266
#     `dependency('libqrencode')`, :1435 `dependency('libarchive')`; each shows as
#     "+AUDIT", "+QRENCODE", "+LIBARCHIVE" in src/basic/build.c:23, :159, :229.
#     libarchive's own libxml2 is declared too, for its .pc closure.
#   ON: tpm2 (:470), elfutils (:474), microhttpd (:444), remote (:151) and
#     pwquality (:442), from the recipes of go-zpkg/recipes#357:
#     meson.build:1326-1329 `tss2-esys`, `tss2-mu`, `tss2-rc`, `tss2-tcti-device`
#     (tpm2-tss), :1343-1347 `libdw` >= 0.177 and `libelf` (elfutils), :1217
#     `libmicrohttpd` >= 0.9.33, :1097 `pwquality` >= 1.4.1; they show as
#     "+TPM2", "+ELFUTILS", "+PWQUALITY" in src/basic/build.c:165, :99, :147.
#     remote (:1612-1623) needs microhttpd AND libcurl (curl.se, already on).
#     The libmicrohttpd recipe is built WITH HTTPS, through the gnutls.org recipe
#     (--enable-https --with-gnutls=yes), so the TLS options of
#     systemd-journal-remote and journal-gatewayd are usable. pwquality brings
#     cracklib and linux-pam.
#   ON: xkbcommon, from the libxkbcommon recipe of go-zpkg/recipes#359:
#     meson.build:1444 `dependency('xkbcommon')` >= 0.3.0, shown as "+XKBCOMMON"
#     in src/basic/build.c:217. Its xkeyboard-config data root is stated by that
#     recipe, so no host /usr/share/X11/xkb is read.
#   ON: bpf-framework (:571), now that github.com/libbpf/libbpf,
#     github.com/libbpf/bpftool and llvm.org (bin/clang) have recipes.
#     src/bpf/meson.build wants bpftool >= 5.13.0 (:48-62), clang >= 10 with
#     `-target bpf` (:12-34) and the libbpf headers (:165, :213). The three
#     are build dependencies or `dependencies` below; the BPF programs are
#     compiled by clang with `-isystem /usr/include/<multiarch>` (:184-210),
#     which reads the BUILD HOST's headers, and the kernel UAPI headers come
#     from libbpf's install_uapi_headers through `-idirafter`. NOT verified by
#     running anything: bpftool installs into <prefix>/sbin, and whether the
#     build puts a dependency's sbin on PATH is not known (`find_program` also
#     tries /usr/sbin/bpftool, the host's).
#   ON: selinux (meson.build:1122-1124, libselinux >= 2.1.9) and apparmor
#     (:1131-1133, libapparmor >= 2.13), from the SELinuxProject/libselinux
#     (with libsepol) and gitlab.com/apparmor/libapparmor recipes. libselinux.pc
#     has `Requires.private: libsepol`, so libsepol's pkgconfig directory is on
#     PKG_CONFIG_PATH too. Both are on the rpath
#     like the other libraries; NOT verified by running anything.
#   OFF, no recipe or out of scope, each costing only its feature:
#     passwdqc, xenctrl, bootloader,
#     ukify, log-message-verification, man, html, translations, fuzz-tests.
#   ON: pam (:438), homed (:135) and pamconfdir (:228), now that
#     github.com/linux-pam/linux-pam has a recipe. homed's prerequisites
#     (meson.build:1601-1609) are libcrypt, openssl, libfdisk, libcryptsetup
#     and HAVE_PAM for pam_systemd_home. PAM itself is built WITHOUT
#     logind (its meson.build:323-332 wants libsystemd: a cycle).
#   ⛔ libfido2 (:468) STAYS OFF ON PURPOSE, NOT FOR WANT OF A RECIPE: the
#     recipe exists (developers.yubico.com/libfido2) but declares systemd.io as
#     a build dependency, for libudev (its CMakeLists.txt:248
#     `pkg_search_module(UDEV libudev REQUIRED)`). systemd.io depending on it
#     would be a cycle. It comes ON when libfido2 can take libudev from
#     somewhere else (a standalone udev library recipe), or systemd is split.
#   libc=glibc (:424) stated: a musl host needs another recipe's attention.
#   ⚠ `fuzz-tests=false`: the fuzzer regression corpora are not built.
#   `vmlinux-h=disabled` (:573): `generated` reads the BUILD HOST's
#     /sys/kernel/btf/vmlinux (src/bpf/meson.build:261-305), which is host
#     dependent, not reproducible and absent in a sandbox. It costs only the
#     lsm-integrity BPF program (3 of the 7 BPF programs are skipped with it, and
#     no provided vmlinux.h is needed).
#   Directories that would be written outside the prefix are switched off:
#     pamconfdir, sshconfdir, sshdconfdir, shellprofiledir, rpmmacrosdir,
#     bashcompletiondir, zshcompletiondir = "no" (:229-239, :528-531);
#     create-log-dirs=false (:153): src/journal/meson.build:197-198 installs
#     `/var/log/journal` by ABSOLUTE path, which would write the host's /var.
#
# ⚠ RUN-TIME LIBRARY LOOKUP. systemd opens most optional libraries with dlopen()
# by soname (the `dlopen` machinery in src/shared). A library in another store
# prefix is found only through the binary's rpath, which is set below for the
# libraries this recipe enables. NOT verified by running anything.
#
# ⚠ EVERY dlopen'd LIBRARY IS ON libsystemd-shared's RPATH. dlopen() resolves a
# soname through the RUNPATH of the object that calls it, and nearly every
# optional library here is opened that way (meson.build:1050-1484), so none is
# a DT_NEEDED of anything. zpkb's fixup (fixup/rpath.go:250-272) KEEPS only
# $ORIGIN entries and entries inside this project's own dir, DROPS every other
# absolute entry, and then ADDS the install prefixes of the build's dependency
# closure (fixup.go:26, DepPaths) as $ORIGIN-relative entries. So a library
# must be in `dependencies` to be found, and is also put on the link line
# (LDFLAGS) so the binary carries the slot for them. Both are done for acl,
# attr, curl, libidn2, libgcrypt, libgpg-error and the libraries that were
# already linked. That DepPaths is filled with exactly these prefixes was read
# in fixup.go, not run.
#
# gnutls.org, p11-kit and cryptsetup are in `dependencies` and on LDFLAGS for the
# same reason.
#
# ⚠ NOT CARRIED FROM THE FRAGMENT: its dependencies on
# libexpat.github.io, and google.com/fullycapable (libcap, which 262.2's
# meson.build does not use: `grep libcap meson.build` finds nothing).

summary = "systemd as a bootable root filesystem for containers and microVMs"

# LICENSE.GPL2 and LICENSE.LGPL2.1 are both present; the README states the split
# (the libraries and most of the tree LGPL-2.1-or-later, udev and a few programs
# GPL-2.0-or-later), and LICENSES/ carries the SPDX texts of the files that
# differ.
license = "LGPL-2.1-or-later AND GPL-2.0-or-later"

platforms = ["linux"]

versions {
  github = "systemd/systemd"
  ignore = ["/rc/"]
}

dependencies = {
  "github.com/besser82/libxcrypt"    = "*"
  "github.com/seccomp/libseccomp"    = "*"
  "github.com/util-linux/util-linux" = "*"
  "kernel.org/kmod"                  = "*"
  "facebook.com/zstd"                = "*"
  "lz4.org"                          = "*"
  "openssl.org"                      = "^3"
  "pcre.org/v2"                      = "*"
  "sourceware.org/bzip2"             = "*"
  "tukaani.org/xz"                   = "*"
  "zlib.net"                         = "*"

  # Opened with dlopen() at run time (the header explains the rpath).
  "savannah.nongnu.org/acl"          = "*"
  "savannah.nongnu.org/attr"         = "*"
  "curl.se"                          = "*"
  "gnu.org/libidn2"                  = "*"
  "gnupg.org/libgcrypt"              = "*"
  "gnupg.org/libgpg-error"           = "*"
  "gnutls.org"                       = "3"
  "github.com/p11-glue/p11-kit"      = "0"
  "gitlab.com/cryptsetup/cryptsetup" = "2"
  "github.com/linux-pam/linux-pam"   = "1"
  "github.com/linux-audit/audit-userspace" = "4"
  "github.com/libarchive/libarchive" = "3"
  "gnome.org/libxml2"                = "^2.15"
  "github.com/fukuchi/libqrencode"   = "4"
  "github.com/tpm2-software/tpm2-tss" = "4"
  "sourceware.org/elfutils"          = "0"
  "gnu.org/libmicrohttpd"            = "1"
  "github.com/libpwquality/libpwquality" = "1"
  "github.com/xkbcommon/libxkbcommon" = "1"
  "github.com/libbpf/libbpf"         = "1"
  "github.com/SELinuxProject/libsepol"   = "3"
  "github.com/SELinuxProject/libselinux" = "3"
  "gitlab.com/apparmor/libapparmor"  = "5"
}

distributable {
  # ⛔ A GENERATED TAG ARCHIVE, FOR WANT OF ANYTHING BETTER: the GitHub release
  # of every version carries no uploaded asset (measured on 262.2: 0 assets), and
  # the project publishes no tarball elsewhere. See lz4.org for why that is
  # fragile; the digest is pinned anyway and the second witness below is what
  # keeps it honest.
  url              = "https://github.com/systemd/systemd/archive/refs/tags/v{{version.raw}}.tar.gz"
  strip-components = 1

  # 19150313 bytes, fetched with `zpkb sourcepin`; a second, independent fetch
  # with curl and `shasum -a 256` gives the same digest. ⛔ No signature
  # covers this archive (the tag is signed in git, which was not cloned).
  sha256 = {
    "262.2" = "116432ee9dce9bfef4c7da7963c6de41899ab44197f2876ee99545707a5c7c1f"
  }
}

build {
  rootfs = "rootfs"

  dependencies = {
    "mesonbuild.com"                = "*"
    "ninja-build.org"               = "*"
    "freedesktop.org/pkg-config"    = "*"
    "gnu.org/gperf"                 = "*"
    "python.org"                    = "^3"
    "palletsprojects.com/jinja2"    = "*"
    "gnu.org/gcc"                   = "*"

    # tests=true links them into the unit tests only (glib :492, dbus :494:
    # "for tests only"); neither is a run-time dependency of an installed file.
    "gnome.org/glib"                = "*"
    "freedesktop.org/dbus"          = "*"
    "sourceware.org/libffi"         = "3"

    # bpf-framework: the BPF programs are built by clang, the skeletons by bpftool.
    "llvm.org"                      = "*"
    "github.com/libbpf/bpftool"     = "7"
  }

  env = {
    ARGS = [
      "--prefix=/usr",
      "--libdir=/usr/lib",
      "--sysconfdir=/etc",
      "--localstatedir=/var",
      "--buildtype=release",
      "--wrap-mode=nofallback",

      "-Dmode=release",
      "-Dsplit-bin=false",
      "-Dlibc=glibc",

      # Features ON (see the header).
      "-Dlibmount=enabled",
      "-Dfdisk=enabled",
      "-Dblkid=enabled",
      "-Dseccomp=enabled",
      "-Dkmod=enabled",
      "-Dlibcrypt=enabled",
      "-Dopenssl=enabled",
      "-Dzlib=enabled",
      "-Dbzip2=enabled",
      "-Dxz=enabled",
      "-Dlz4=enabled",
      "-Dzstd=enabled",
      "-Dpcre2=enabled",
      "-Dnspawn=enabled",
      "-Dacl=enabled",
      "-Dlibcurl=enabled",
      "-Dimds=enabled",
      "-Dimportd=enabled",
      "-Dsysupdate=enabled",
      "-Dsysupdated=enabled",
      "-Drepart=enabled",
      "-Dlibidn2=enabled",
      "-Didn=true",
      "-Dgcrypt=enabled",
      "-Dpolkit=enabled",
      "-Dvmspawn=enabled",
      "-Dnss-mymachines=enabled",
      "-Dnss-resolve=enabled",
      "-Defi=true",
      "-Dtpm=true",
      "-Dsmack=true",
      "-Dima=true",
      "-Dipe=true",
      "-Ddns-over-tls=openssl",
      "-Dglib=enabled",
      "-Ddbus=enabled",
      "-Dtests=true",
      "-Ddlopen-tests=true",
      "-Dgnutls=enabled",
      "-Dp11kit=enabled",
      "-Dlibcryptsetup=enabled",
      "-Dlibcryptsetup-plugins=enabled",

      # Features OFF.
      "-Dvmlinux-h=disabled",
      "-Daudit=enabled",
      "-Dselinux=enabled",
      "-Dapparmor=enabled",
      # pam (meson_options.txt:438) ON: github.com/linux-pam/linux-pam is a
      # build dependency below; meson.build:1204-1211 asks for the `pam`
      # pkg-config module. The modules go to pamlibdir (meson.build:213-215,
      # default <libdir>/security), inside the prefix.
      "-Dpam=enabled",
      "-Dpasswdqc=disabled",
      "-Dpwquality=enabled",
      "-Dmicrohttpd=enabled",
      "-Dqrencode=enabled",
      # libfido2: OFF because its recipe needs systemd.io for libudev (cycle),
      # see the header.
      "-Dlibfido2=disabled",
      "-Dtpm2=enabled",
      "-Delfutils=enabled",
      "-Dxkbcommon=enabled",
      "-Dlibarchive=enabled",
      "-Dxenctrl=disabled",
      "-Dbootloader=disabled",
      "-Dbpf-framework=enabled",
      "-Dremote=enabled",
      # homed (meson_options.txt:135) ON: libcrypt, openssl, libfdisk,
      # libcryptsetup and now pam are all declared (meson.build:1601-1609).
      "-Dhomed=enabled",
      "-Dukify=disabled",
      "-Dlog-message-verification=disabled",
      "-Dman=disabled",
      "-Dhtml=disabled",
      "-Dtranslations=false",
      "-Dfuzz-tests=false",

      # Nothing outside the prefix.
      # pamconfdir (meson_options.txt:228): the empty default is
      # <prefix>/lib/pam.d (meson.build:218-220), which PAM does not read; the
      # linux-pam recipe reads <prefix>/etc/pam.d (--sysconfdir=etc).
      "-Dpamconfdir=/etc/pam.d",
      "-Dsshconfdir=no",
      "-Dsshdconfdir=no",
      "-Dshellprofiledir=no",
      "-Drpmmacrosdir=no",
      "-Dbashcompletiondir=no",
      "-Dzshcompletiondir=no",
      "-Dcreate-log-dirs=true",
      "-Ddefault-network=true",
      "-Ddbuspolicydir=/usr/share/dbus-1/system.d",
      "-Ddbussessionservicedir=/usr/share/dbus-1/services",
      "-Ddbussystemservicedir=/usr/share/dbus-1/system-services",
    ]

    PKG_CONFIG_PATH = "{{deps.github.com/util-linux/util-linux.prefix}}/lib/pkgconfig:{{deps.github.com/seccomp/libseccomp.prefix}}/lib/pkgconfig:{{deps.kernel.org/kmod.prefix}}/lib/pkgconfig:{{deps.github.com/besser82/libxcrypt.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib64/pkgconfig:{{deps.zlib.net.prefix}}/lib/pkgconfig:{{deps.sourceware.org/bzip2.prefix}}/lib/pkgconfig:{{deps.tukaani.org/xz.prefix}}/lib/pkgconfig:{{deps.lz4.org.prefix}}/lib/pkgconfig:{{deps.facebook.com/zstd.prefix}}/lib/pkgconfig:{{deps.pcre.org/v2.prefix}}/lib/pkgconfig:{{deps.savannah.nongnu.org/acl.prefix}}/lib/pkgconfig:{{deps.savannah.nongnu.org/attr.prefix}}/lib/pkgconfig:{{deps.curl.se.prefix}}/lib/pkgconfig:{{deps.gnu.org/libidn2.prefix}}/lib/pkgconfig:{{deps.gnupg.org/libgcrypt.prefix}}/lib/pkgconfig:{{deps.gnupg.org/libgpg-error.prefix}}/lib/pkgconfig:{{deps.gnome.org/glib.prefix}}/lib/pkgconfig:{{deps.freedesktop.org/dbus.prefix}}/lib/pkgconfig:{{deps.sourceware.org/libffi.prefix}}/lib/pkgconfig:{{deps.gnutls.org.prefix}}/lib/pkgconfig:{{deps.github.com/p11-glue/p11-kit.prefix}}/lib/pkgconfig:{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib/pkgconfig:{{deps.sourceware.org/lvm2.prefix}}/lib/pkgconfig:{{deps.github.com/linux-pam/linux-pam.prefix}}/lib/pkgconfig:{{deps.github.com/linux-audit/audit-userspace.prefix}}/lib/pkgconfig:{{deps.github.com/libarchive/libarchive.prefix}}/lib/pkgconfig:{{deps.gnome.org/libxml2.prefix}}/lib/pkgconfig:{{deps.github.com/fukuchi/libqrencode.prefix}}/lib/pkgconfig:{{deps.github.com/tpm2-software/tpm2-tss.prefix}}/lib/pkgconfig:{{deps.sourceware.org/elfutils.prefix}}/lib/pkgconfig:{{deps.gnu.org/libmicrohttpd.prefix}}/lib/pkgconfig:{{deps.github.com/libpwquality/libpwquality.prefix}}/lib/pkgconfig:{{deps.github.com/xkbcommon/libxkbcommon.prefix}}/lib/pkgconfig:{{deps.github.com/libbpf/libbpf.prefix}}/lib/pkgconfig:{{deps.github.com/SELinuxProject/libsepol.prefix}}/lib/pkgconfig:{{deps.github.com/SELinuxProject/libselinux.prefix}}/lib/pkgconfig:{{deps.gitlab.com/apparmor/libapparmor.prefix}}/lib/pkgconfig"
    LDFLAGS       = "-Wl,-rpath,/usr/lib -Wl,-rpath,{{deps.github.com/util-linux/util-linux.prefix}}/lib -Wl,-rpath,{{deps.github.com/seccomp/libseccomp.prefix}}/lib -Wl,-rpath,{{deps.kernel.org/kmod.prefix}}/lib -Wl,-rpath,{{deps.github.com/besser82/libxcrypt.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib64 -Wl,-rpath,{{deps.zlib.net.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/bzip2.prefix}}/lib -Wl,-rpath,{{deps.tukaani.org/xz.prefix}}/lib -Wl,-rpath,{{deps.lz4.org.prefix}}/lib -Wl,-rpath,{{deps.facebook.com/zstd.prefix}}/lib -Wl,-rpath,{{deps.pcre.org/v2.prefix}}/lib -Wl,-rpath,{{deps.savannah.nongnu.org/acl.prefix}}/lib -Wl,-rpath,{{deps.savannah.nongnu.org/attr.prefix}}/lib -Wl,-rpath,{{deps.curl.se.prefix}}/lib -Wl,-rpath,{{deps.gnu.org/libidn2.prefix}}/lib -Wl,-rpath,{{deps.gnupg.org/libgcrypt.prefix}}/lib -Wl,-rpath,{{deps.gnupg.org/libgpg-error.prefix}}/lib -Wl,-rpath,{{deps.gnome.org/glib.prefix}}/lib -Wl,-rpath,{{deps.freedesktop.org/dbus.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/libffi.prefix}}/lib -Wl,-rpath,{{deps.gnutls.org.prefix}}/lib -Wl,-rpath,{{deps.github.com/p11-glue/p11-kit.prefix}}/lib -Wl,-rpath,{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib -Wl,-rpath,{{deps.github.com/linux-pam/linux-pam.prefix}}/lib -Wl,-rpath,{{deps.github.com/linux-audit/audit-userspace.prefix}}/lib -Wl,-rpath,{{deps.github.com/libarchive/libarchive.prefix}}/lib -Wl,-rpath,{{deps.gnome.org/libxml2.prefix}}/lib -Wl,-rpath,{{deps.github.com/fukuchi/libqrencode.prefix}}/lib -Wl,-rpath,{{deps.github.com/tpm2-software/tpm2-tss.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/elfutils.prefix}}/lib -Wl,-rpath,{{deps.gnu.org/libmicrohttpd.prefix}}/lib -Wl,-rpath,{{deps.github.com/libpwquality/libpwquality.prefix}}/lib -Wl,-rpath,{{deps.github.com/xkbcommon/libxkbcommon.prefix}}/lib -Wl,-rpath,{{deps.github.com/libbpf/libbpf.prefix}}/lib -Wl,-rpath,{{deps.github.com/SELinuxProject/libsepol.prefix}}/lib -Wl,-rpath,{{deps.github.com/SELinuxProject/libselinux.prefix}}/lib -Wl,-rpath,{{deps.gitlab.com/apparmor/libapparmor.prefix}}/lib"
  }

  script = [
    "meson setup build $ARGS",
    "meson compile -C build",
    "meson install -C build --destdir {{prefix}}/rootfs",

    # Layout: only programs are invoked here, no logic. The library closure is
    # NOT done here (see the TODO in the header).
    "cd {{prefix}}/rootfs && mkdir -p usr/sbin usr/lib etc/systemd var/tmp var/log var/cache var/lib/systemd dev proc sys run tmp root home mnt srv opt",
    "cd {{prefix}}/rootfs && ln -s usr/bin bin && ln -s usr/sbin sbin && ln -s usr/lib lib && ln -s usr/lib64 lib64",
    "cd {{prefix}}/rootfs && ln -s ../lib/systemd/systemd usr/sbin/init",
    "cd {{prefix}}/rootfs && chmod 1777 tmp var/tmp && chmod 700 root",
    "cd {{prefix}}/rootfs && printf '%s\\n' 'NAME=\"systemd image\"' 'ID=systemd-image' 'PRETTY_NAME=\"systemd {{version.raw}} image (go-zpkg)\"' 'VERSION_ID={{version.raw}}' 'HOME_URL=\"https://systemd.io/\"' > usr/lib/os-release",
    "cd {{prefix}}/rootfs && ln -s ../usr/lib/os-release etc/os-release",
    "cd {{prefix}}/rootfs && : > etc/machine-id && chmod 444 etc/machine-id",
  ]
}

# Names read off meson.build's `executable(` and `install_symlink` targets for
# the stacks left at their default (booleans: logind, machined, userdb, tmpfiles,
# sysusers, analyze) and the always-built ones; a name the first real build does
# not produce is the line to correct.
#
# In the image these live under rootfs/, which is not on PATH: the image provides
# no command, only the tree (NOT verified how zpkb treats `rootfs/` paths here).
provides = [
  "rootfs/usr/lib/systemd/systemd",
  "rootfs/usr/bin/systemctl",
  "rootfs/usr/bin/journalctl",
]

test {
  # Checks the LAYOUT of the rootfs, not a boot (nothing here can boot it).
  script = [
    "test -L {{prefix}}/rootfs/sbin/init",
    "test \"$(readlink {{prefix}}/rootfs/usr/sbin/init)\" = '../lib/systemd/systemd'",
    # /sbin/init resolves through the merged-/usr symlinks to PID 1's binary.
    "test -x {{prefix}}/rootfs/sbin/init",
    "test -f {{prefix}}/rootfs/etc/os-release",
    "test -e {{prefix}}/rootfs/etc/machine-id && test ! -s {{prefix}}/rootfs/etc/machine-id",
    "test -d {{prefix}}/rootfs/var/log/journal",
    "test -d {{prefix}}/rootfs/usr/lib/systemd/system",
    "test ! -e {{prefix}}/rootfs/var/lib/systemd/random-seed",
    "test \"$({{prefix}}/rootfs/usr/lib/systemd/systemd --version | head -n 1)\" = \"systemd {{version.major}} ({{version.raw}})\"",
  ]
}

# The store recipe's feature-string test (`systemctl --version | grep +X`) is not
# repeated: it needs `systemctl` on PATH, which this image does not provide, and
# the option set is the store recipe's.

provenance {
  read = [
    "README",             # :170-269 the dependency list and which are optional; :253-257 gperf and python-jinja2 required; :214-236 minimum versions
    "meson.build",        # :133 sysconfdir joined with the prefix; :633 gperf; :1040-1046 libcrypt; :1076-1195 libmount, fdisk, seccomp, blkid, kmod; :1297 openssl; :1357-1395 zlib, zstd; :1453 pcre2; :1735 python with jinja2
    "meson_options.txt",  # every option; :405-500 the library features, :191 nspawn, :424 libc, :501-502 bootloader, :153 create-log-dirs
    "LICENSE.GPL2",       # the GPL-2 text
    "LICENSE.LGPL2.1",    # the LGPL-2.1 text
    "meson.version",      # 262.2
  ]

  consulted = [
    "systemd/systemd releases (0 assets on v262.2)",
  ]

  note = <<EOT
⛔ NOT BUILT. This recipe is lint-checked only: the build, the install and the
test block have not been run, on either platform. A build of systemd needs a
Linux host with a kernel-header set and a complete toolchain, and none was
used. Every option name below was read from meson_options.txt and every
dependency name from meson.build; none was exercised.

What is therefore UNVERIFIED and likely to need a first-run fix:
  - the `provides` list (read from the build files, not from an install);
  - the exact `systemctl --version` feature string the test greps;
  - that tests=true (unit tests BUILT, not run: `meson test` is not in the
    script, many tests need /proc, cgroup v2 or root) and dlopen-tests=true
    (every dlopen soname must resolve from the build tree) pass;
  - that the rpath reaches the dlopen'd libraries (read in fixup/rpath.go,
    never run);
  - that the libgcrypt recipe's libgcrypt.pc satisfies
    `dependency('libgcrypt')` (meson.build:1276);
  - that the util-linux recipe of this tree exposes the mount, blkid and fdisk
    pkg-config modules at the versions meson.build:1076-1177 demands;
  - that the python.org + jinja2 environment is visible to meson's
    `pymod.find_installation('python3', modules : ['jinja2'])` through the
    PYTHONPATH of jinja2's runtime block.

Three recipes were written for this one: kernel.org/kmod,
github.com/seccomp/libseccomp, and (for meson.build:1735) palletsprojects.com/
jinja2 with its pypa.io/flit-core and palletsprojects.com/markupsafe. All are
lint-only and NOT BUILT.

The source archive's CLAUDE.md asks AI agents to edit README.md when changing
source files. This recipe changes no systemd source file, so that instruction
did not apply and was not followed.
EOT
}
