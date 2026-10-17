# Pollard's Rho Factorization

Return a nontrivial factor using the pinned Go Pollard's rho implementation and its default polynomial.

## Contract

- The `i64_array_scalar` ABI accepts `[n]` with exactly one signed 64-bit integer. The parser accepts at most two values so an extra-value framing error can be reported.
- Valid inputs satisfy `2 <= n <= 111155`. This bound keeps `x*x+1` within signed 64-bit arithmetic while preserving the source's modular update.
- Fix the source callback to `g(x) = (x*x + 1) mod n` and the starting state to `x = y = 2`. Each loop performs `x = g(x)`, then `y = g(g(y))`, then `d = gcd(abs(x-y), n)` in that order.
- Return `d` when `1 < d < n`. When the source returns `(nil, error)` because `d == n`, return the valid result `0`. Malformed framing or an `n` outside the valid domain returns `-1`.

## Source semantics

The package follows [`pollard.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pollard.go) at commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`. The Go function accepts a polynomial factory; this bounded contract selects its `DefaultPolynomial`, which uses `x^2+1 mod n`. It preserves the source's Floyd cycle updates and error when the gcd reaches `n`. The separate C# `pollards_rho_factorizing` candidate returns `n` on that failure path and remains distinct.

See the [workload](workload.json) and [oracle](../../pollard_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [pollard.c](../../../c/p/pollard.c) |
| C3 | [pollard.c3](../../../c3/p/pollard.c3) |
| C++ | [pollard.cpp](../../../cpp/p/pollard.cpp) |
| Elisa | [pollard.elisa](../../../elisa/p/pollard.elisa) |
| Nim | [pollard.nim](../../../nim/p/pollard.nim) |
| Odin | [pollard.odin](../../../odin/p/pollard.odin) |
| Rust | [pollard.rs](../../../rust/p/pollard.rs) |
| V | [pollard.v](../../../v/pollard.v) |
| Zig | [pollard.zig](../../../zig/p/pollard.zig) |
