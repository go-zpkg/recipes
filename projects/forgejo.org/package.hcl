# forgejo.org — Forgejo: a self-hosted Git forge (a soft fork of Gitea), one
# binary, `forgejo`.
#
# ⛔ WHY forgejo.org AND NOT codeberg.org/forgejo/forgejo: the pantry names a
# project by its own domain when it has one (nodejs.org, cmake.org), and by
# host/owner/repo only when the code lives on a forge and nothing else names it
# (github.com/...). Forgejo's Go module is `forgejo.org` and its site is
# forgejo.org/download; Codeberg is where the source is hosted, which may move.

summary = "Forgejo: a self-hosted, lightweight software forge (Git hosting, issues, pull requests, CI), one binary"

# LICENSE at the root of the tarball: GPL-3.0-or-later since Forgejo v9.
license = "GPL-3.0-or-later"

# linux: built natively on each arch's runner. openbsd: NATIVE too, inside a
# guest (target.go: "These builds are NATIVE — the compiler runs inside the BSD
# guest"), because the `sqlite` build tag pulls mattn/go-sqlite3, which is cgo,
# and a cgo cross build to OpenBSD needs an OpenBSD sysroot nobody here has.
platforms = ["linux", "openbsd"]

# The tags of the repository, through Codeberg's Gitea-compatible API (50 per
# page, newest first). `-dev` tags (`v18.0.0-dev`) are branch markers and do not
# match: the pattern has nothing after the third number.
versions {
  url   = "https://codeberg.org/api/v1/repos/forgejo/forgejo/tags?limit=50"
  match = "/\"name\":\"v\\d+\\.\\d+\\.\\d+\"/"
  strip = [
    "/\"name\":\"v/",
    "/\"$/",
  ]
}

distributable {
  url              = "https://codeberg.org/forgejo/forgejo/releases/download/v{{version.raw}}/forgejo-src-{{version.raw}}.tar.gz"
  strip-components = 1

  # 53822061 bytes, recorded with `zpkb sourcepin --sig auto --version 17.0.2`.
  #
  # ⭐ THE ARCHIVE IS SIGNED AND THE SIGNATURE WAS VERIFIED against the key the
  # project publishes: EB114F5E6C0DC2BCDD183550A4B61A2DC5923710
  # (Forgejo <contact@forgejo.org>), the fingerprint listed on
  # https://forgejo.org/download/; the key file came from keys.openpgp.org by
  # that fingerprint, no keyserver search. Signed 2026-11-18T18:32:50Z.
  # Detached signature:
  #   https://codeberg.org/forgejo/forgejo/releases/download/v17.0.2/forgejo-src-17.0.2.tar.gz.asc
  sha256 = {
    "17.0.2" = "5b08f6c24819aeb62b80f2f50f989cfcdfde0a8887f66438cbf32b556b1b6efb"
  }
}

provides = [
  "bin/forgejo",
]

build {
  dependencies = {
    # go.mod:5 `toolchain go1.26.11`; GOTOOLCHAIN=local below means a go.dev
    # older than that is refused rather than a newer one fetched behind our back.
    "go.dev" = ">=1.26.11"
  }

  # ⭐ NO NODE. The source archive is the RELEASE one: public/assets/{js,css,
  # fonts} are already built (19 MB, checked in the unpacked 17.0.2 tree), and
  # vendor/ (122 MB) carries every Go module, so the build needs neither
  # nodejs.org nor the network. Building from a git checkout would need both.
  #
  # `go build` and not `make`: the Makefile's only jobs here are to pick the
  # tags and stamp the version. Its `backend` target also regenerates code and
  # may reach for the frontend; the release archive does not need either.
  script = <<EOT
go build $ARGS -tags "$TAGS" -ldflags "$GO_LDFLAGS" -o "{{prefix}}/bin/forgejo" .
EOT

  env {
    CGO_ENABLED = "1"
    GOTOOLCHAIN = "local"
    GOFLAGS     = "-mod=vendor"
    GOPROXY     = "off"
    ARGS = [
      "-v",
      "-trimpath",
      "-buildvcs=false",
    ]
    # The release tags, as `forgejo --version` reports them for the upstream
    # binary: assets and templates embedded, tzdata embedded, SQLite with
    # unlock-notify.
    TAGS = "bindata timetzdata sqlite sqlite_unlock_notify"
    # Makefile:117-119: `-s -w` and the five -X. With a VERSION file present the
    # Makefile sets FORGEJO_VERSION, RELEASE_VERSION and FORGEJO_VERSION_API all
    # to its content, so that is what is stamped here.
    GO_LDFLAGS = [
      "-s",
      "-w",
      "-X 'main.ReleaseVersion={{version}}'",
      "-X 'main.Version={{version}}'",
      "-X 'main.ForgejoVersion={{version}}'",
      "-X 'main.Tags=bindata timetzdata sqlite sqlite_unlock_notify'",
    ]
  }
}

test {
  script = [
    "case \"$(forgejo --version)\" in \"forgejo version {{version}} \"*) ;; *) echo \"unexpected: $(forgejo --version)\" >&2; exit 1 ;; esac",
    "forgejo web --help",
  ]
}

provenance {
  read = [
    "Makefile",   # :84-119 the version stamping and -ldflags; :145 TAGS; :898-899 the `go build` line
    "go.mod",     # :3 `go 1.26.0`, :5 `toolchain go1.26.11`; :75 mattn/go-sqlite3 (cgo)
    "VERSION",    # 17.0.2, which the Makefile reads as FORGEJO_VERSION
  ]

  consulted = [
    "openbsd ports www/gitea (Makefile, patches/patch-custom_conf_app_example_ini)",
  ]

  note = <<EOT
Read in the unpacked forgejo-src-17.0.2 archive, the thing this recipe builds.

  - The archive carries vendor/ and the built public/assets, so no Node and no
    module download.
  - `sqlite` is mattn/go-sqlite3 (cgo). OpenBSD's own gitea port avoids cgo only
    because Gitea moved to modernc.org/sqlite (`purego` tag); Forgejo 17 has not,
    so the OpenBSD artifact must be built natively in a guest. A cross build with
    CGO_ENABLED=0 and no `sqlite` tag does produce a valid OpenBSD ELF (measured,
    with `bindata timetzdata`), but without SQLite: PostgreSQL or MySQL only.
  - The only OpenBSD port patch is to custom/conf/app.example.ini (paths under
    /etc, /var); nothing in Go code. That belongs to a package's install layout,
    not to this binary.
EOT
}
