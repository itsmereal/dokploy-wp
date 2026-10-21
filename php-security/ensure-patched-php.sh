#!/bin/sh
set -eu

# Official fixed releases for CVE-2026-109618 and CVE-2026-109619.
check_patched() {
    php -r '
        $minimum = ["8.2" => "8.2.35", "8.3" => "8.3.36", "8.4" => "8.4.27", "8.5" => "8.5.12"];
        $branch = PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;
        if (!isset($minimum[$branch])) {
            fwrite(STDERR, "Unsupported PHP branch: " . PHP_VERSION . PHP_EOL);
            exit(2);
        }
        if (version_compare(PHP_VERSION, $minimum[$branch], "<")) {
            fwrite(STDERR, "PHP " . PHP_VERSION . " requires " . $minimum[$branch] . " or newer" . PHP_EOL);
            exit(1);
        }
        echo "Patched PHP verified: " . PHP_VERSION . PHP_EOL;
    '
}

if check_patched; then
    exit 0
else
    status=$?
fi
[ "${1:-}" != "--check-only" ] || exit "$status"
[ "$status" -eq 1 ] || exit "$status"

# Preserve the base image's SAPI, configuration and extension ABI. Until
# upstream publishes patched PHP 8.3 images, rebuild the official fixed source.
[ "$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')" = "8.3" ] || {
    echo 'No source fallback for this branch; use a patched upstream image.' >&2
    exit 1
}
source_version=8.3.36
source_sha256=dd54693aa334c5c4d72e9aee96b082c2473750a18a6c1d105789c93a3b1692fd
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT HUP INT TERM
php -m | sort > "$workdir/modules.before"
configure_options=$(php-config --configure-options)
apache_dependencies=
case "$configure_options" in
    *--with-apxs2*) apache_dependencies=apache2-dev ;;
esac
apt-get update
# PHPIZE_DEPS and the configure options come from the trusted PHP base image.
# shellcheck disable=SC2086
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ${PHPIZE_DEPS:-autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c} \
    $apache_dependencies ca-certificates curl xz-utils libargon2-dev \
    libcurl4-openssl-dev libonig-dev libreadline-dev libsodium-dev \
    libsqlite3-dev libssl-dev libxml2-dev zlib1g-dev
curl -fsSL "https://www.php.net/distributions/php-${source_version}.tar.xz" \
    -o "$workdir/php.tar.xz"
echo "$source_sha256  $workdir/php.tar.xz" | sha256sum -c -
mkdir "$workdir/source"
tar -xJf "$workdir/php.tar.xz" -C "$workdir/source" --strip-components=1
cd "$workdir/source"
export CFLAGS="${PHP_CFLAGS:-}" CPPFLAGS="${PHP_CPPFLAGS:-}" LDFLAGS="${PHP_LDFLAGS:-}"
# shellcheck disable=SC2086
./configure $configure_options
make -j"${PHP_BUILD_JOBS:-2}"
make install
cp "$workdir/php.tar.xz" /usr/src/php.tar.xz
php -m | sort > "$workdir/modules.after"
comm -23 "$workdir/modules.before" "$workdir/modules.after" > "$workdir/modules.missing"
if [ -s "$workdir/modules.missing" ]; then
    echo 'PHP extensions missing after the source upgrade:' >&2
    cat "$workdir/modules.missing" >&2
    exit 1
fi
rm -rf /var/lib/apt/lists/*
check_patched
