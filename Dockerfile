# ---- MySQL source stage (multi-arch) ----
ARG MYSQL_VERSION=9.7
FROM mysql:${MYSQL_VERSION} AS mysql-source

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

# # 3. Install Python 3.15 from source
# # First, install the required build dependencies.
# RUN apt-get update && apt-get install -y \
#     build-essential pkg-config wget ca-certificates xz-utils \
#     libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
#     libffi-dev liblzma-dev libncursesw5-dev libgdbm-dev libgdbm-compat-dev \
#     uuid-dev tk-dev \
#     && rm -rf /var/lib/apt/lists/*
# 
# # Then, download, compile, and install Python 3.15.2.
# RUN wget https://www.python.org/ftp/python/3.15.2/Python-3.15.2.tar.xz \
#     && tar -xf Python-3.15.2.tar.xz \
#     && cd Python-3.15.2 \
#     && ./configure --prefix=/usr/local \
#     && make -j$(nproc) \
#     && make altinstall \
#     && rm -rf ../Python-3.15.2 ../Python-3.15.2.tar.xz
# 
# # 4. Install Node.js 26 (using NodeSource repository)
# RUN curl -fsSL https://deb.nodesource.com/setup_26.x | bash - \
#     && apt-get install -y nodejs \
#     && rm -rf /var/lib/apt/lists/*
# 
# # 5. Install Bun (official installer)
# RUN curl -fsSL https://bun.com/install | bash \
#     && mv /root/.bun/bin/bun /usr/local/bin/bun
# 
# # 6. Install Rust 1.99 (via rustup)
# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.99.0
# ENV PATH="/root/.cargo/bin:${PATH}"
# 
# # 7. Install Java 25 (via SDKMAN, Temurin — not in Debian Trixie repos)
# RUN apt-get update && apt-get install -y zip \
#     && rm -rf /var/lib/apt/lists/* \
#     && curl -s https://get.sdkman.io | bash \
#     && bash -c 'source "$HOME/.sdkman/bin/sdkman-init.sh" && { sdk install java 25.0.1-tem || sdk install java 25-tem; } && sdk install maven && sdk install gradle'
# ENV JAVA_HOME="/root/.sdkman/candidates/java/current"
# ENV M2_HOME="/root/.sdkman/candidates/maven/current"
# ENV GRADLE_HOME="/root/.sdkman/candidates/gradle/current"
# ENV PATH="${JAVA_HOME}/bin:${M2_HOME}/bin:${GRADLE_HOME}/bin:${PATH}"
# 
# # 8. Install .NET SDK 10.0 (via dotnet-install.sh — not Debian repos)
# RUN apt-get update && apt-get install -y libicu-dev \
#     && rm -rf /var/lib/apt/lists/* \
#     && wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh \
#     && chmod +x /tmp/dotnet-install.sh \
#     && /tmp/dotnet-install.sh --channel 10.0 \
#     && rm -f /tmp/dotnet-install.sh
# ENV DOTNET_ROOT="/root/.dotnet"
# ENV PATH="/root/.dotnet:${PATH}"
# 
# # 9. Install Nginx 1.31 from the official Nginx repository
# RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian/ trixie nginx" | tee /etc/apt/sources.list.d/nginx.list \
#     && curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg \
#     && apt-get update && apt-get install -y nginx \
#     && rm -rf /var/lib/apt/lists/*
# 
# # 10. Install PostgreSQL 18.6 from the official PGDG repository
# RUN sh -c 'echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
#     && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg \
#     && apt-get update && apt-get install -y postgresql-18 \
#     && rm -rf /var/lib/apt/lists/*

# 11. Install MySQL 9.7 LTS from the official multi-arch image
# Copy the MySQL server, client tools, and supporting files from the official image.
COPY --from=mysql-source /usr/sbin/mysqld /usr/sbin/mysqld
COPY --from=mysql-source /usr/bin/mysql /usr/bin/mysql
COPY --from=mysql-source /usr/bin/mysqladmin /usr/bin/mysqladmin
COPY --from=mysql-source /usr/bin/mysqldump /usr/bin/mysqldump

# Copy shared libraries required by the MySQL binaries.
# The paths differ by architecture, so we use TARGETARCH to select the correct source.
COPY --from=mysql-source /usr/lib64/mysql/ /usr/lib/mysql/
COPY --from=mysql-source /usr/lib64/libssl.so.3 /usr/lib/${TARGETARCH}-linux-gnu/
COPY --from=mysql-source /usr/lib64/libcrypto.so.3 /usr/lib/${TARGETARCH}-linux-gnu/
COPY --from=mysql-source /usr/lib64/libncurses.so.6 /usr/lib/${TARGETARCH}-linux-gnu/
COPY --from=mysql-source /usr/lib64/libtinfo.so.6 /usr/lib/${TARGETARCH}-linux-gnu/

# Copy the official entrypoint script (used for initializing the data directory).
COPY --from=mysql-source /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create the mysql user and group, and set up the data directory and runtime directories.
RUN groupadd -r mysql && useradd -r -g mysql mysql \
    && mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld

# Expose the default MySQL port.
EXPOSE 3306

# # 12. Install Redis 8.10 from source
# RUN apt-get update && apt-get install -y build-essential tcl \
#     && wget https://github.com/redis/redis/archive/refs/tags/8.10.2.tar.gz \
#     && tar -xzf 8.10.2.tar.gz \
#     && cd redis-8.10.2 \
#     && make \
#     && make install \
#     && cd .. \
#     && rm -rf redis-8.10.2 8.10.2.tar.gz
# 
# # 13. Install MongoDB 9.0 from the official MongoDB repository
# RUN curl -fsSL https://pgp.mongodb.com/server-9.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-9.gpg \
#     && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-9.gpg ] https://repo.mongodb.org/apt/debian trixie/mongodb-org/9.0 main" | tee /etc/apt/sources.list.d/mongodb-org-9.0.list \
#     && apt-get update && apt-get install -y mongodb-org \
#     && rm -rf /var/lib/apt/lists/*

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
#   docker buildx build --platform linux/amd64,linux/arm64 -t mdsiaofficial/joat:1.0.0 --push .
# Run on Apple Silicon (ARM64) natively:
#   docker run -it mdsiaofficial/joat:1.0.0