# VUR - Void Linux Package Repository

Repository for automated building and distribution of custom packages for Void Linux.

## Overview

This project provides an automated CI/CD pipeline using GitHub Actions to build packages from `srcpkgs/` templates and publish them to binary repositories accessible via `xbps-src` and `xbps-install`.

The system:
- Automatically detects new packages in `srcpkgs/`
- Respects package dependencies when building
- Signs packages with a private key for secure distribution
- Publishes compiled binaries to a dedicated Git branch (`repository-x86_64-glibc`)

## Architecture

```
srcpkgs/
├── package1/
│   └── template          # Package definition (Void Linux format)
├── package2/
│   └── template
└── ...

scripts/
├── set-environment       # Sets target architecture variables
├── generate-build-order.kts  # Analyzes dependencies, generates build order
├── clone-and-prepare     # Clones void-packages, merges custom packages
├── build-packages        # Executes xbps-src for each package
├── index-packages        # Copies compiled .xbps files
├── sign-packages         # Signs binaries with private key
└── push-repository       # Pushes binaries to Git branch

.github/workflows/
├── build-latest.yml      # Main CI: builds and publishes on push to master
└── check.yml             # PR validation: lints templates and test builds
```

## How It Works

### On Push to `master`

1. **GitHub Actions** triggers `build-latest.yml`
2. **generate-build-order.kts** parses all `srcpkgs/*/template` files, analyzes `depends=` declarations
3. Packages are built in dependency order via `xbps-src`
4. Compiled `.xbps` files are automatically collected
5. Packages are signed with your private key
6. Binaries are pushed to branch `repository-x86_64-glibc`

### Installation from Repository

Users can install packages by adding the repository:

```bash
echo 'repository=https://raw.githubusercontent.com/YOUR_ORG/VUR/repository-x86_64-glibc' | sudo tee /etc/xbps.d/vur.conf
sudo xbps-install -S
sudo xbps-install -S your-package
```

## Adding New Packages

1. Create directory: `srcpkgs/your-package/`
2. Add `template` file following [Void Linux template format](https://docs.voidlinux.org/xbps/repositories/index.html)
3. Declare dependencies in `depends="package1 package2 ..."`
4. Push to `master` → CI automatically builds and publishes

### Updating `common/shlibs`

The `shlibs` file maps shared libraries (`.so`) to their providing packages. Update it when adding packages that provide libraries:

**Format:**
```
LIBRARY_NAME PACKAGE_NAME-VERSION_REVISION
```

**Example:**
If your package provides `libmylib.so.1` in version `1.0.0_1`:
```
libmylib.so.1 mylib-1.0.0_1
```

**Important notes:**
- Only add entries for packages that provide `.so` files in `/usr/lib/`
- The number after `.so` is the **ABI major version** (changes only on breaking changes)
- Void Linux uses this for automatic dependency resolution
- This file is automatically merged with Void's official `shlibs` during build

## Configuration

### GitHub Secrets Required

Configure these in repository Settings → Secrets and variables → Actions:

| Secret | Purpose | How to Generate |
|--------|---------|-----------------|
| `PRIVATE_PEM_PASSPHRASE` | Password for your private signing key | Your choice |
| `PEM_PAT` | GitHub token to access private key repository | [GitHub PAT (classic)](https://github.com/settings/tokens) with `repo` scope |
| `ACCESS_GIT` | GitHub token for pushing binary branches | [GitHub PAT (classic)](https://github.com/settings/tokens) with `repo` scope |

### Setup Steps

1. **Generate signing key** (or use existing):
   ```bash
   openssl genrsa -out private.pem 4096
   ```

2. **Create private repository** `hyprland-void-private-pem`:
   - Store `private.pem` in repository root
   - Keep repository private

3. **Generate GitHub PAT**:
   - Go to [github.com/settings/tokens](https://github.com/settings/tokens)
   - Create "Tokens (classic)" with `repo` scope
   - Use same token for `PEM_PAT` and `ACCESS_GIT`

4. **Configure secrets**:
   - `PRIVATE_PEM_PASSPHRASE`: Passphrase for your private.pem
   - `PEM_PAT`: GitHub token from step 3
   - `ACCESS_GIT`: Same token or different one

## Project Structure

- **hyprland-void/** - Main package repository with build scripts
  - `srcpkgs/` - Package templates
  - `scripts/` - Build automation scripts
  - `.github/workflows/` - CI/CD workflows
  - `common/shlibs` - Shared library definitions

- **Workflows**:
  - `build-latest.yml` - Production builds (triggered on push to master)
  - `check.yml` - CI validation (runs on PRs and test branches)

## Credits

This project is based on and adapted from [Makrennel/hyprland-void](https://github.com/Makrennel/hyprland-void), which provides an excellent reference implementation for automated Hyprland package building and distribution on Void Linux.

## License

See [LICENSE](LICENSE) file.
