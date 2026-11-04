# Use the latest stable Debian (Trixie)
FROM debian:trixie

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install base system tools, GCC 16, G++ 16, Python 3.15, SQLite 3.54, Nginx 1.31
RUN apt-get update && apt-get install -y \
    curl wget git unzip build-essential ca-certificates gnupg lsb-release \
    gcc-16 g++-16 \
    python3.15 python3-pip python3.15-venv \
    sqlite3 \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Node.js 26 (using NodeSource repository)
RUN curl -fsSL https://deb.nodesource.com/setup_26.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. Install Bun 1.4.4 (official installer)
RUN curl -fsSL https://bun.com/install | bash \
    && mv /root/.bun/bin/bun /usr/local/bin/bun

# 4. Install Rust 1.99.0 (via rustup)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.99.0
ENV PATH="/root/.cargo/bin:${PATH}"

# 5. Install Java 25 (OpenJDK 25 from Debian repos)
RUN apt-get update && apt-get install -y openjdk-25-jdk \
    && rm -rf /var/lib/apt/lists/*

# 6. Install .NET SDK 10.0 (Microsoft package repository)
RUN wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y dotnet-sdk-10.0 \
    && rm -rf /var/lib/apt/lists/*

# 7. Install PostgreSQL 18.6 and Redis 8.10 (from Debian repos)
RUN apt-get update && apt-get install -y postgresql-18 redis-server \
    && rm -rf /var/lib/apt/lists/*

# 8. Install MySQL 9.7 LTS (from Oracle's official APT repository)
RUN curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /usr/share/keyrings/mysql.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian/ trixie mysql-9.7-lts" | tee /etc/apt/sources.list.d/mysql.list \
    && apt-get update && apt-get install -y mysql-server \
    && rm -rf /var/lib/apt/lists/*

# 9. Install MongoDB 9.0 (Community Edition from official repo)
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-9.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-9.0.gpg \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-9.0.gpg ] http://repo.mongodb.org/apt/debian trixie/mongodb-org/9.0 main" | tee /etc/apt/sources.list.d/mongodb-org-9.0.list \
    && apt-get update && apt-get install -y mongodb-org \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command (keeps container running for interactive use)
CMD ["/bin/bash"]