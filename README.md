# JOAT — Jack of All Trades (current_version: 1.0.4)

A single Debian Trixie–based Docker image bundling the latest versions of the most
common runtimes, compilers, web servers, and databases. One image, zero setup.

## Included Versions

| Category        | Tool          | Provider          | Version |
|-----------------|---------------|-------------------|---------|
| Runtime         | Node.js       | NodeSource        | 26      |
| Runtime         | .NET SDK      | Microsoft         | 11.0    |
| Runtime         | Java          | SDKMAN (Temurin)  | 25      |
| Runtime         | Python        | APT (Debian)      | 3.13    |
| Runtime         | Bun           | Bun               | 1.4.4   |
| Runtime         | Rust          | rustup            | 1.99.0  |
| Compiler        | GCC           | APT (Debian sid)  | 16      |
| Compiler        | G++           | APT (Debian sid)  | 16      |
| Web Server      | Nginx         | Nginx             | 1.31    |
| Database        | PostgreSQL    | PGDG              | 18.6    |
| Database        | SQLite        | APT (Debian)      | 3.54    |
| Cache / Store   | Redis         | APT (Debian)      | 8.0.2   |

## Usage

```bash
docker run -it --rm mdsiaofficial/joat
```

The image is multi-platform and supports both `linux/amd64` (Intel/AMD) and
`linux/arm64` (Apple Silicon M1/M2/M3, Windows on ARM). Docker automatically
pulls the correct variant for your machine.

## How to Release a New Version

Docker images are built and published automatically by GitHub Actions. You do
not need to build or push Docker images manually.

### 1. Make your changes

Edit the `Dockerfile` or any other files as needed.

### 2. Commit your changes

```sh
git add .
git commit -m "feat: describe your changes here"
```

### 3. Create and push a version tag

GitHub Actions triggers on version tags (e.g., `v1.0.0`, `v1.0.1`, `v1.3.1`).

```sh
git tag v1.x.x
git push origin v1.x.x
```

You can also push to `main` to trigger a build with the `latest` tag:

```sh
git push origin main
```

### 4. GitHub Actions does the rest

When you push a tag, the CI pipeline (`.github/workflows/docker-publish.yml`):

1. Checks out your code
2. Sets up QEMU for cross-platform emulation
3. Sets up Docker Buildx
4. Logs in to Docker Hub
5. Builds the image for `linux/amd64` and `linux/arm64`
6. Pushes a multi-arch manifest to `mdsiaofficial/joat`

After the workflow completes, users can run:

```sh
docker pull mdsiaofficial/joat:latest
docker run -it --rm mdsiaofficial/joat:latest
```

### Required GitHub Secrets

Make sure these secrets are configured in your GitHub repository
(Settings → Secrets and variables → Actions):

| Secret             | Description              |
|--------------------|--------------------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN`    | Your Docker Hub access token |

## Local Development (Optional)

If you want to build and test the image locally before pushing:

```sh
# Build for your current platform only
docker build -t mdsiaofficial/joat:latest .

# Run it
docker run -it --rm mdsiaofficial/joat:latest
```

To build for multiple platforms locally (requires QEMU):

```sh
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name multiarch --use
docker buildx build --platform linux/amd64,linux/arm64 -t mdsiaofficial/joat:latest .

```
