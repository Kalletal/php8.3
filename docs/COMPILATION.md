# PHP 8.3 Compilation Guide for Synology Geminilake

This guide explains how to cross-compile PHP 8.3.28 for Synology DS920+ (Geminilake architecture) using the spksrc toolchain.

## Prerequisites

### System Requirements

- **OS**: Linux (Ubuntu 20.04+ or Debian 11+ recommended)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 20GB free
- **Time**: 2-4 hours for full toolchain + PHP build

### Required Packages

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    automake \
    autoconf \
    libtool \
    pkg-config \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    gettext \
    intltool \
    bison \
    flex \
    gperf \
    texinfo \
    xmlto \
    imagemagick \
    bc \
    libncurses5-dev \
    ncurses-dev \
    zlib1g-dev \
    libssl-dev \
    libgmp-dev \
    libxml2-dev \
    libxslt1-dev

# Install GNU Make 4.x if not present
make --version  # Should be 4.0+
```

## Method 1: Using spksrc (Recommended)

### Step 1: Clone spksrc

```bash
cd ~/
git clone https://github.com/SynoCommunity/spksrc.git
cd spksrc
```

### Step 2: Setup Environment

```bash
# Configure for Geminilake (DS920+)
make setup

# This downloads cross-compilation toolchains
# Takes 30-60 minutes on first run
```

### Step 3: Create PHP Cross File

Create `cross/php83/Makefile`:

```makefile
PKG_NAME = php
PKG_VERS = 8.3.28
PKG_EXT = tar.gz
PKG_DIST_NAME = $(PKG_NAME)-$(PKG_VERS).$(PKG_EXT)
PKG_DIST_SITE = https://www.php.net/distributions
PKG_DIR = $(PKG_NAME)-$(PKG_VERS)

DEPENDS = cross/openssl cross/curl cross/libxml2 cross/sqlite \
          cross/libpng cross/libjpeg cross/freetype cross/icu

HOMEPAGE = https://www.php.net/
COMMENT  = PHP 8.3 scripting language
LICENSE  = PHP-3.01

CONFIGURE_ARGS  = --enable-fpm --with-fpm-user=http --with-fpm-group=http
CONFIGURE_ARGS += --enable-cli --enable-opcache --enable-mbstring
CONFIGURE_ARGS += --with-curl --with-openssl --with-zlib --with-bz2
CONFIGURE_ARGS += --enable-mysqlnd --with-pdo-mysql --with-mysqli
CONFIGURE_ARGS += --with-pdo-sqlite --with-sqlite3
CONFIGURE_ARGS += --with-libxml --enable-xml --enable-simplexml
CONFIGURE_ARGS += --enable-intl --with-gd --with-jpeg --with-freetype
CONFIGURE_ARGS += --enable-zip --enable-sockets --enable-bcmath
CONFIGURE_ARGS += --disable-debug --disable-rpath

include ../../mk/spksrc.cross-cc.mk
```

### Step 4: Build PHP

```bash
# Build for Geminilake (DS920+)
cd ~/spksrc
make arch-geminilake-7.2 php83

# This will:
# 1. Download PHP 8.3.28 source
# 2. Cross-compile for Geminilake
# 3. Build all dependencies
# 4. Install to build/php83/install/
```

Build time: **1-3 hours** depending on your system.

### Step 5: Extract Binaries

```bash
# Find the installation directory
INSTALL_DIR=$(find ~/spksrc/build -name "php83" -type d | grep install)

# Copy to your package
cd /path/to/php8.3/spk/php83

# Copy binaries
mkdir -p files/bin
cp -v $INSTALL_DIR/usr/local/bin/php files/bin/
cp -v $INSTALL_DIR/usr/local/sbin/php-fpm files/bin/

# Copy libraries
mkdir -p files/lib
cp -rv $INSTALL_DIR/usr/local/lib/php files/lib/

# Copy extensions
mkdir -p files/lib/php/extensions
cp -v $INSTALL_DIR/usr/local/lib/php/extensions/no-debug-non-zts-*/*.so \
   files/lib/php/extensions/

# Verify
ls -lh files/bin/
ls -lh files/lib/php/extensions/
```

### Step 6: Rebuild SPK

```bash
cd /path/to/php8.3
bash scripts/build-spk.sh
```

Your SPK is now **ready for installation** on DS920+!

## Method 2: Manual Cross-Compilation

### Step 1: Download Toolchain

```bash
# Get Synology DSM 7 Geminilake toolchain
wget https://sourceforge.net/projects/dsgpl/files/DSM%207.0%20Tool%20Chains/Intel%20x86%20Linux%204.4.180%20%28Geminilake%29/geminilake-gcc850_glibc226_x86_64-GPL.txz

# Extract
tar xf geminilake-gcc850_glibc226_x86_64-GPL.txz
export TOOLCHAIN_ROOT=$(pwd)/x86_64-pc-linux-gnu
export PATH=$TOOLCHAIN_ROOT/bin:$PATH
export CC=x86_64-pc-linux-gnu-gcc
export CXX=x86_64-pc-linux-gnu-g++
export AR=x86_64-pc-linux-gnu-ar
export RANLIB=x86_64-pc-linux-gnu-ranlib
```

### Step 2: Build Dependencies

You need to cross-compile these first:
1. **zlib** (required for compression)
2. **OpenSSL** (required for encryption)
3. **libxml2** (required for XML)
4. **curl** (required for networking)
5. **SQLite** (required for database)
6. **ICU** (required for intl extension)
7. **libpng, libjpeg, freetype** (required for GD)

**This is complex and error-prone.** Use spksrc instead (Method 1).

### Step 3: Compile PHP

```bash
cd spk/php83/vendor
tar xzf php-8.3.28.tar.gz
cd php-8.3.28

./configure \
    --host=x86_64-pc-linux-gnu \
    --prefix=/usr/local \
    --enable-fpm \
    --with-fpm-user=http \
    --with-fpm-group=http \
    --enable-cli \
    --enable-opcache \
    --with-openssl=$TOOLCHAIN_ROOT \
    --with-curl=$TOOLCHAIN_ROOT \
    --with-zlib=$TOOLCHAIN_ROOT \
    --enable-mbstring \
    --with-pdo-mysql \
    --with-mysqli \
    --with-sqlite3 \
    --enable-intl \
    --with-gd

make -j$(nproc)
make install DESTDIR=$(pwd)/install
```

Copy binaries to `files/` as in Method 1, Step 5.

## Method 3: Docker-Based Build

### Using spksrc Docker Image

```bash
# Pull spksrc Docker image
docker pull synocommunity/spksrc

# Run build
docker run -it --rm \
    -v $(pwd):/spksrc/packages/php83 \
    synocommunity/spksrc \
    make arch-geminilake-7.2 php83

# Extract from Docker volume
```

## Verification

### Test Binaries

```bash
# Check architecture
file files/bin/php
# Should show: ELF 64-bit LSB executable, x86-64 ...

# Check dependencies (on Synology or in QEMU)
ldd files/bin/php
# All libraries should resolve

# Test execution (on target or emulator)
./files/bin/php -v
# Should print: PHP 8.3.28 ...

./files/bin/php -m
# Should list compiled-in modules
```

### Test Extensions

```bash
# On target system after installation
php -m | grep -E "curl|openssl|pdo_mysql|intl|gd"
```

## Extension-Specific Notes

### OpenSSL
- **Critical**: Must link against DSM's OpenSSL for security updates
- Path: `/lib/libssl.so`, `/lib/libcrypto.so`
- Configure: `--with-openssl=/usr`

### MySQL/MariaDB
- Use mysqlnd (native driver): `--enable-mysqlnd --with-pdo-mysql --with-mysqli`
- Socket: `/run/mysqld/mysqld.sock` (configured in php.ini)

### GD (Graphics)
- Requires: libpng, libjpeg, freetype
- Modern syntax: `--with-gd --with-jpeg --with-freetype`
- Old syntax deprecated in PHP 8.x

### Intl (Internationalization)
- Requires: ICU library (libicu-dev)
- Large dependency (~12MB)
- Essential for Unicode/locale support

### Opcache
- **Always enable**: `--enable-opcache`
- Configured in php.ini (already optimized)
- Critical for performance

## Troubleshooting

### "configure: error: Cannot find OpenSSL's libraries"
```bash
# Ensure OpenSSL is in toolchain
export PKG_CONFIG_PATH=$TOOLCHAIN_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
```

### "undefined reference to `libiconv`"
```bash
# Install libiconv in toolchain first
# Or add: --with-iconv=$TOOLCHAIN_ROOT
```

### Extensions Won't Load on Synology
```bash
# Check ABI compatibility
php -i | grep "PHP Extension Build"
# Must match between CLI and extensions

# Check library paths
export LD_LIBRARY_PATH=/var/packages/php83/target/lib:$LD_LIBRARY_PATH
```

### "Bus error" or Segmentation Fault
- Wrong architecture (not x86_64)
- ABI mismatch (glibc version)
- Rebuild with correct toolchain

## Performance Tips

### Parallel Builds
```bash
# Use all CPU cores
make -j$(nproc)

# Or specific count
make -j8
```

### Caching
```bash
# spksrc caches downloads and builds
# Keep ~/spksrc/distrib/ and ~/spksrc/build/ between builds
```

### Incremental Builds
```bash
# Rebuild only PHP, not dependencies
cd ~/spksrc
make -C cross/php83 clean
make arch-geminilake-7.2 php83
```

## Advanced: Custom Extensions

### Adding PECL Extensions

1. **Download extension source**
   ```bash
   wget https://pecl.php.net/get/redis-5.3.7.tgz
   tar xzf redis-5.3.7.tgz
   cd redis-5.3.7
   ```

2. **Prepare build environment**
   ```bash
   export PATH=$TOOLCHAIN_ROOT/bin:$PATH
   /path/to/php83/bin/phpize
   ```

3. **Configure and build**
   ```bash
   ./configure --with-php-config=/path/to/php83/bin/php-config
   make
   make install
   ```

4. **Add to package**
   ```bash
   cp modules/redis.so /path/to/php8.3/spk/php83/files/lib/php/extensions/
   ```

5. **Update extension manifest**
   Edit `spk/php83/files/conf/extension_options.json` to include new extension.

## Resources

- **spksrc Documentation**: https://github.com/SynoCommunity/spksrc/wiki
- **PHP Build System**: https://www.php.net/manual/en/internals2.buildsys.php
- **Synology Toolchains**: https://sourceforge.net/projects/dsgpl/files/
- **Cross-Compilation Guide**: https://wiki.osdev.org/Cross-Compiler

## Next Steps

After successful compilation:

1. **Rebuild SPK** with binaries: `bash scripts/build-spk.sh`
2. **Test on DS920+**: Install via Package Center
3. **Verify extensions**: `php -m`
4. **Run test suite**: `bash tests/integration/extension-selection/install-wizard.sh`
5. **Document changes**: Update README with build date/version

---

**Pro Tip**: Once you have working binaries, cache them separately. Rebuilding PHP from scratch takes hours, but rebuilding the SPK structure takes seconds!
