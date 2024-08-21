# FMglee

[![Package Version](https://img.shields.io/hexpm/v/fmglee)](https://hex.pm/packages/fmglee)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/fmglee/)

FMGlee is a simple string formatting library. It exposes two main APIs to format 
strings, one driven by pipes, and the other more inline.

```sh
gleam add fmglee
```
```gleam
import fmglee
import gleeunit/should

fmglee.new("Number %d, float %f, string %s")
|> fmglee.d(99)
|> fmglee.f(12.9)
|> fmglee.s("Hello!")
|> fmglee.build
|> should.equal("Number 99, float 12.9, string Hello!")

// OR

fmglee.fmt("Number %d, float %f, string %s", with: [fmglee.D(99), fmglee.F(12.9), fmglee.S("Hello!")])
|> should.equal("Number 99, float 12.9, string Hello!")
```

Further documentation can be found at <https://hexdocs.pm/fmglee>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
