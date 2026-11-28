# github.com/tox-dev/filelock — filelock: a platform-independent file lock.
#
# ⛔ WRITTEN FROM THE SDIST'S OWN FILES (go-zpkg/packages#440), as a dependency
# of python-discovery (`filelock>=3.16.1`, its pyproject.toml:49) and of
# virtualenv.pypa.io (`filelock>=3.24.2,<5`, its pyproject.toml:57).

summary = "filelock: platform-independent file lock for Python"

# pyproject.toml:19 `license = "MIT"`; the sdist carries LICENSE.
license = "MIT"

versions {
  github = "tox-dev/filelock/tags"
}

dependencies = {
  # pyproject.toml:23 `requires-python = ">=3.11"`.
  "python.org" = "^3.11"
}

distributable {
  url              = "https://files.pythonhosted.org/packages/source/f/filelock/filelock-{{version.raw}}.tar.gz"
  strip-components = 1

  # Fetched with `zpkb sourcepin`, and byte-identical to the sha256 PyPI's simple
  # index (pypi.org/simple/filelock/) records for the sdist.
  sha256 = {
    "4.3.0" = "143407310acf479e82d88068e3b9a6486f45fb410c0ed8729fe7359eaabeb6f1"

    # 4.3.1: 742330 bytes, recorded 2026-11-24 with `zpkb sourcepin --version
    # 4.3.1` (one fetch; not compared with PyPI's index for this version).
    "4.3.1" = "4c5ee627c401f1863ac6a0de9a14a28d3bb5f8c730b45e2fd6e5dbc79cf34b9e"

    # 4.3.2: 744182 bytes, recorded 2026-11-28 with `zpkb sourcepin --version
    # 4.3.2`; equals the sdist's sha256 in pypi.org/pypi/filelock/4.3.2/json.
    "4.3.2" = "4f0a21c70447782453c06bb20a9863ee385ead1abaef22049af79289496851b3"
  }
}

build {
  dependencies = {
    "pypa.io/hatchling"                        = "*"
    "github.com/ofek/hatch-vcs"                = "*"
    "github.com/hynek/hatch-fancy-pypi-readme" = "*"
    "github.com/tox-dev/python-sbom"           = "*"
  }

  script = [
    {
      # pyproject.toml:2-8 requires hatch-fancy-pypi-readme, hatch-vcs,
      # hatchling>=1.29 and python-sbom[hatch], backend hatchling.build;
      # :129-130 enable the vcs and python-sbom build hooks. The version is
      # VCS-derived (:126) and the sdist is not a checkout, so it is pinned from
      # the resolved one. The sdist omits the README.md that the readme hook's
      # fragment names (:128), so an empty one stands in and the wheel's long
      # description is empty.
      run = <<EOT
set -eu
test -e README.md || : > README.md
SETUPTOOLS_SCM_PRETEND_VERSION="{{version.raw}}" python3 -m pip install --no-build-isolation --no-index --no-deps --no-compile --prefix "{{prefix}}" .
EOT
    },
  ]
}

runtime {
  env = {
    PYTHONPATH = "{{prefix}}/lib/python{{deps.python.org.version.major}}.{{deps.python.org.version.minor}}/site-packages:$PYTHONPATH"
  }
}

test {
  script = [
    {
      run = <<EOT
set -eu
PYVER=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
cat > probe.py <<'PYEOF'
import importlib.metadata, filelock
assert importlib.metadata.version("filelock") == "{{version.raw}}"
print(filelock.__file__)
PYEOF
PYTHONPATH="{{prefix}}/lib/python$PYVER/site-packages" python3 probe.py > where.txt
grep "{{prefix}}" where.txt >/dev/null || { echo "filelock was not imported from this prefix" >&2; cat where.txt >&2; exit 1; }
EOT
    },
  ]
}

provenance {
  read = [
    "pyproject.toml", # :2-8 build-system; :19 license MIT; :23 requires-python >=3.11; :38-41 dynamic readme, version (no dependencies table); :125-130 Hatch config
    "LICENSE",        # present in the sdist
  ]

  consulted = [
    "pypi.org/simple/filelock/", # the second witness for the digest
  ]

  note = <<EOT
NOT BUILT. Written from the project's own files; neither the build nor the
test block has been run, on either platform.

⛔ NOT SIGNED. The digest is witnessed by PyPI's simple index and by the bytes
`zpkb sourcepin` fetched, which agree.

The empty README.md in the build script is a workaround for an sdist that does
not carry the file its readme hook reads. That the build fails without it has
not been measured; the workaround costs only the long description.

The probe does not check that the interpreter is 3.11 or later; the `^3.11`
dependency on python.org does, if the tree's python.org recipe resolves one.
EOT
}
