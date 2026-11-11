# Use the latest stable Debian (Trixie)
FROM debian:trixie

# Build args for multi-platform (buildx) support
ARG TARGETPLATFORM
ARG TARGETARCH
ARG VERSION=dev
ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install essential build tools and core utilities
RUN apt-get update && apt-get install -y \
    curl wget git unzip zip build-essential ca-certificates gnupg lsb-release \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# 2. Install GCC 16 and G++ 16 from the Debian unstable (sid) repository
# This is necessary because they are not in the stable Trixie repo.
RUN echo "deb http://deb.debian.org/debian sid main" > /etc/apt/sources.list.d/sid.list \
    && apt-get update \
    && apt-get install -y gcc-16 g++-16 \
    && rm -f /etc/apt/sources.list.d/sid.list \
    && rm -rf /var/lib/apt/lists/*

# 3. Install Python 3.13 from Debian's official repositories
# First, install the required build dependencies.
RUN apt-get update && apt-get install -y \
    build-essential pkg-config wget ca-certificates xz-utils \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev libncursesw5-dev libgdbm-dev libgdbm-compat-dev \
    uuid-dev tk-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    && rm -rf /var/lib/apt/lists/*

# 4. Install Node.js 26 (using NodeSource repository)
RUN curl -fsSL https://deb.nodesource.com/setup_26.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 5. Install Bun (official installer)
RUN curl -fsSL https://bun.com/install | bash \
    && mv /root/.bun/bin/bun /usr/local/bin/bun

# 6. Install Rust 1.99 (via rustup)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.99.0
ENV PATH="/root/.cargo/bin:${PATH}"

# 7. Install Java 25 (via SDKMAN, Temurin — not in Debian Trixie repos)
RUN apt-get update && apt-get install -y zip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -s https://get.sdkman.io | bash \
    && bash -c 'source "$HOME/.sdkman/bin/sdkman-init.sh" && { sdk install java 25.0.1-tem || sdk install java 25-tem; } && sdk install maven && sdk install gradle'
ENV JAVA_HOME="/root/.sdkman/candidates/java/current"
ENV M2_HOME="/root/.sdkman/candidates/maven/current"
ENV GRADLE_HOME="/root/.sdkman/candidates/gradle/current"
ENV PATH="${JAVA_HOME}/bin:${M2_HOME}/bin:${GRADLE_HOME}/bin:${PATH}"

# 8. Install .NET SDK 11.0 (via dotnet-install.sh — not Debian repos)
RUN apt-get update && apt-get install -y libicu-dev \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --channel 11.0 \
    && rm -f /tmp/dotnet-install.sh
ENV DOTNET_ROOT="/root/.dotnet"
ENV PATH="/root/.dotnet:${PATH}"

# 9. Install Nginx 1.31 from the official Nginx repository
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian/ trixie nginx" | tee /etc/apt/sources.list.d/nginx.list \
    && curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg \
    && apt-get update && apt-get install -y nginx \
    && rm -rf /var/lib/apt/lists/*

# 10. Install PostgreSQL 18.6 from the official PGDG repository
RUN sh -c 'echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg \
    && apt-get update && apt-get install -y postgresql-18 \
    && rm -rf /var/lib/apt/lists/*

# 11. Install Redis 8.0.2 from Debian Trixie apt (not from source)
RUN apt-get update && apt-get install -y redis-server redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Build args for multi-platform (buildx) support are already defined at the top of the stage.

LABEL org.opencontainers.image.title="joat" \
      org.opencontainers.image.description="Jack Of All Trades development environment image" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/mdsiaofficial/joat"

# Set working directory
WORKDIR /app

# Default command (keeps container running for interactive use)
CMD ["/bin/bash"]

# Build with:
#   docker buildx build --platform linux/amd64,linux/arm64 -t mdsiaofficial/joat:1.x.x --push .
# Run on Apple Silicon (ARM64) natively:
#   docker run -it mdsiaofficial/joat:1.x.x