Name
====

content-storage-cli - CLI client to interact with [content-storage](https://github.com/hythm7/content-storage.git)


Installation
============

```bash
# using zef
zef install content-storage-cli

# or using Pakku
pakku add content-storage-cli
```

Usage
=====

```bash

content-storage-cli.raku distributions
content-storage-cli.raku builds
content-storage-cli.raku users

content-storage-cli.raku my distributions
content-storage-cli.raku my builds

content-storage-cli.raku search distributions <name>
content-storage-cli.raku search builds        <name>
content-storage-cli.raku search users         <name>

content-storage-cli.raku my user

content-storage-cli.raku delete distribution <distribution>
content-storage-cli.raku delete build        <build>
content-storage-cli.raku delete user         <user>

content-storage-cli.raku build log <build>

content-storage-cli.raku update user <user> [--password=<Str>]
content-storage-cli.raku update user <user> [--admin]

content-storage-cli.raku update my password <password>

content-storage-cli.raku download <identity>

content-storage-cli.raku add <archive>

content-storage-cli.raku login    <username> <password>

content-storage-cli.raku register <username> <password> [--firstname=<Str>] [--lastname=<Str>] [--email=<S

content-storage-cli.raku logout

```

Config
======

```bash
cat ~/.content-storage-cli/config.json
{
  "storage": {
    "name": "my-storage",
    "api": {
      "uri": "https://content-storage.pakku.org/api/v1/",
      "page": 1,
      "limit": 20
    }
  },
  "verbose": true
}

# Replace uri with the storage api uri.
```

Author
======

Haytham Elganiny <elganiny.haytham@gmail.com>

Copyright and License
=====================

Copyright 2024 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

