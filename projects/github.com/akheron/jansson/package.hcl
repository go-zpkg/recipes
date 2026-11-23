# github.com/akheron/jansson — a C library for encoding, decoding and manipulating
# JSON data. It is the JSON layer of jose (and through it of clevis), which is
# why it is here: the pantry had no recipe of its own for it (the only mention
# was a dependency name in nghttp2.org).
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (configure.ac, README.rst, LICENSE) at
# 2.15.1, the newest release (GitHub `releases/latest` is v2.15.1) and the one
# whose release tarball carries a generated `configure`. The digest below is
# computed from my own download.
#
# No dependency: libjansson links nothing but libc. Autotools is used rather
# than the CMakeLists.txt that ships beside it, because jose and clevis find the
# library through `jansson.pc` and both build systems install it.
# --disable-static: only the shared library is wanted.

summary = "jansson: C library for encoding, decoding and manipulating JSON data"

# LICENSE: the MIT licence.
license = "MIT"

versions {
  github = "akheron/jansson"
}

distributable {
  # The release tarball (the GitHub tag archive has no generated `configure`).
  url              = "https://github.com/akheron/jansson/releases/download/v{{version.raw}}/jansson-{{version.raw}}.tar.gz"
  strip-components = 1

  # 2.15.1, computed from the download.
  sha256 = {
    "2.15.1" = "0c7114dc0b2d22a670724a1f95922029d7077c19dbf79a584cb8084d2f267f2f"
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
      "--libdir={{prefix}}/lib",
      "--disable-static",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{hw.concurrency}}",
    "make install",
  ]
}

test {
  dependencies = {
    "gnu.org/gcc" = "*"
  }

  script = [
    "test -f {{prefix}}/include/jansson.h",
    "test -f {{prefix}}/lib/pkgconfig/jansson.pc",
    "grep -q '^Version: {{version.raw}}' {{prefix}}/lib/pkgconfig/jansson.pc",
    # A program linked against the LIBRARY: parse a document, read a value back,
    # build another object and dump it. The binary is run, not only linked.
    {
      fixture = {
        content  = <<EOT
#include <jansson.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
  json_error_t err;
  json_t *root = json_loads("{\"name\":\"jansson\",\"n\":[1,2,3]}", 0, &err);
  if (!root) return 1;
  json_t *name = json_object_get(root, "name");
  if (!json_is_string(name) || strcmp(json_string_value(name), "jansson")) return 2;
  if (json_array_size(json_object_get(root, "n")) != 3) return 3;
  json_t *out = json_pack("{s:s, s:i}", "lib", "jansson", "answer", 42);
  char *s = json_dumps(out, JSON_COMPACT | JSON_SORT_KEYS);
  if (!s || strcmp(s, "{\"answer\":42,\"lib\":\"jansson\"}")) return 4;
  free(s);
  json_decref(out);
  json_decref(root);
  return 0;
}
EOT
        extname = "c"
      }
      run = "gcc $FIXTURE -o jansson-test -I{{prefix}}/include -L{{prefix}}/lib -Wl,-rpath,{{prefix}}/lib -ljansson"
    },
    "./jansson-test",
  ]
}

provenance {
  read = [
    "configure.ac",  # the options; the library version and the pkg-config file
    "README.rst",    # build instructions
    "LICENSE",       # MIT
    "https://github.com/akheron/jansson/releases",
  ]

  consulted = []

  note = <<EOT
Built and run on Linux (aarch64, glibc) with the commands of this file; the test
program above ran against the installed library.

⚠ The release is not signed here (no .asc beside the tarball was read); the
digest is the one computed from the download, and a second witness is not
available.
EOT
}
