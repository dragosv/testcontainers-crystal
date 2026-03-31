# Connection strings

Pre-configured container [modules](../modules/index.md) provide a `database_url` method (or equivalent) that returns a ready-to-use connection string. This eliminates the need to manually construct connection URLs from host, port, and credentials.

## How it works

After starting a module container, call `database_url` (or `connection_url`, `redis_url`) on the container. The connection string includes the mapped host, the random port assigned by Docker, and any configured credentials.

```crystal
container = Testcontainers::PostgresContainer.new
  .with_database("mydb")
  .with_username("user")
  .with_password("pass")

container.start

url = container.database_url
# postgres://user:pass@localhost:55432/mydb
```

## Available connection strings

### PostgreSQL

```crystal
container = Testcontainers::PostgresContainer.new
  .with_database("testdb")
  .with_username("admin")
  .with_password("secret")

container.start
url = container.database_url
# Format: postgres://<username>:<password>@<host>:<port>/<database>
```

### MySQL

```crystal
container = Testcontainers::MysqlContainer.new
  .with_database("testdb")
  .with_username("admin")
  .with_password("secret")

container.start
url = container.database_url
# Format: mysql://<username>:<password>@<host>:<port>/<database>
```

### Redis

```crystal
container = Testcontainers::RedisContainer.new
container.start

url = container.redis_url
# Format: redis://<host>:<port>/0
```

### MongoDB

```crystal
container = Testcontainers::MongoContainer.new
  .with_username("admin")
  .with_password("secret")

container.start
url = container.connection_url
# Format: mongodb://<username>:<password>@<host>:<port>/<database>
```

## Using connection strings in tests

```crystal
require "testcontainers"
require "spec"

describe "Database" do
  it "connects to PostgreSQL" do
    container = Testcontainers::PostgresContainer.new
      .with_database("testdb")
      .with_username("admin")
      .with_password("secret")

    begin
      container.start

      url = container.database_url
      url.should start_with("postgres://")
    ensure
      container.stop rescue nil
      container.remove rescue nil
    end
  end
end
```

!!! tip

    Connection strings automatically use the correct mapped host port, so you never need to worry about port conflicts.
