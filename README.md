# Bitcoin Volta

## Development & Testing

How to run tests:
```bash
# start interactive docker container
./interactive.sh

# download dependencies
mix deps.get

# run tests
mix test

# run all tests
mix test --include slow

# run tests every time you save a file
mix test.watch

# run tests from just one module (core)
cd apps/core
mix test.watch
```

Things to know about bitcoind & lnd integration tests:
- Runtime files for lnd & bitcoind are localted in `temp`
- Binaries for lnd & bitcoind are downloaded to `resources` the first time the tests run
- The contents of `temp` are deleted as the first step after running `mix test` or its varients
