# JOAT — Jack of All Trades

A single Debian Trixie–based Docker image bundling the latest versions of the most
common runtimes, compilers, web servers, and databases. One image, zero setup.

## Included Versions

| Category        | Tool          | Version |
|-----------------|---------------|---------|
| Runtime         | Node.js       | 26      |
| Runtime         | .NET SDK      | 10.0    |
| Runtime         | Java (OpenJDK)| 25      |
| Runtime         | Python        | 3.15    |
| Runtime         | Bun           | 1.4.4   |
| Runtime         | Rust          | 1.99.0  |
| Compiler        | GCC           | 16      |
| Compiler        | G++           | 16      |
| Web Server      | Nginx         | 1.31    |
| Database        | MongoDB       | 9.0     |
| Database        | PostgreSQL    | 18.6    |
| Database        | MySQL         | 9.7 LTS |
| Database        | SQLite        | 3.54    |
| Cache / Store   | Redis         | 8.10    |

## Usage

```bash
docker run -it --rm mdsiaofficial/joat

