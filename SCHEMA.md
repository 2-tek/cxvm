# SCHEMA

## 1. Entities

```sql
CREATE TABLE version (
    id           VARCHAR(64)  PRIMARY KEY,
    version      VARCHAR(64)  NOT NULL UNIQUE,
    channel      VARCHAR(32)  NOT NULL,
    release_date VARCHAR(64)  NOT NULL,
    min_cpp      VARCHAR(32)  NOT NULL,
    description  TEXT,
    is_default   BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE platform (
    id           VARCHAR(64)  PRIMARY KEY,
    os           VARCHAR(32)  NOT NULL,
    arch         VARCHAR(32)  NOT NULL,
    target_triple VARCHAR(64) NOT NULL
);

CREATE TABLE artifact (
    id           VARCHAR(64)  PRIMARY KEY,
    version_id   VARCHAR(64)  NOT NULL REFERENCES version(id) ON DELETE CASCADE,
    platform_id  VARCHAR(64)  NOT NULL REFERENCES platform(id) ON DELETE CASCADE,
    filename     VARCHAR(255) NOT NULL,
    sha256       VARCHAR(64)  NOT NULL,
    size_bytes   BIGINT       NOT NULL
);

CREATE TABLE linux_distro (
    id           VARCHAR(64)  PRIMARY KEY,
    name         VARCHAR(64)  NOT NULL UNIQUE,
    version      VARCHAR(32)  NOT NULL,
    kernel       VARCHAR(64)  NOT NULL,
    rootfs_path  VARCHAR(255) NOT NULL,
    status       VARCHAR(32)  NOT NULL,
    is_ready     BOOLEAN      NOT NULL DEFAULT FALSE
);
```

## 2. Relationships

```text
version -0:*-1:1- artifact
platform -0:*-1:1- artifact
```

## 3. API (/api)

| Method | Path                           | Entity       | Action                                      |
| :----- | :----------------------------- | :----------- | :------------------------------------------ |
| GET    | /api/versions                  | version      | list runtime versions                       |
| GET    | /api/platforms                 | platform     | list platforms                              |
| GET    | /api/artifacts                 | artifact     | list release bundles                        |
| POST   | /api/v1/linux-distro/install   | linux_distro | install Linux distribution rootfs & catalog |
| POST   | /api/v1/linux-distro/uninstall | linux_distro | uninstall Linux distribution rootfs         |
| POST   | /api/v1/linux-distro/setup     | linux_distro | setup and initialize Linux distribution     |
| GET    | /api/v1/linux-distro/status    | linux_distro | inspect active Linux distribution status    |
| GET    | /api/v1/linux-distro/list      | linux_distro | list supported and installed distributions  |
| POST   | /api/v1/reinstall              | cxvm         | deep scan, purge, and clean reinstall       |
