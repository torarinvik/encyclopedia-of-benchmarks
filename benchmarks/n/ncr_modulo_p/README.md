# Binomial coefficient modulo p

## Contract

Compute `n choose r` modulo `p` using the pinned C++ factorial-table algorithm. The `i64_array_scalar` input is exactly `[size, p, n, r]`: the constructor precomputes factorials through `size`, then the query computes `ncr(n, r)`. Require `0 <= n <= size <= 64`, `0 <= r <= 64`, and `2 <= p <= 1009`. Composite moduli are allowed because the source accepts them. Invalid packed inputs return `INT64_MIN`.

The source operation order is preserved: set `fac[0] = 1`, then for each `i` from 1 through `size`, store `(fac[i-1] * i) % p`. The query checks `r > n` first and returns 0, then `r == 1` and returns `n % p`, then `r == 0 || r == n` and returns 1. Otherwise it computes `denominator = (fac[r] * fac[n-r]) % p`, asks extended Euclid for its inverse modulo `p`, returns -1 if no inverse exists, and finally returns `(fac[n] * inverse) % p`. Thus -1 is a valid source result for some composite moduli; it is distinct from the invalid-input sentinel.

The `r > n` branch precedes all table access, so an in-range `r` larger than `size` still returns 0 when `r > n`. For `r <= n`, the bound `n <= size` guarantees every table index is present. The bounded values keep all intermediate products within signed 64-bit range. This differs from exact `binomial_coefficient` and `binomial_calculate`, and from `ncr_combinations`, which accepts real-valued totals.

The canonical pin is TheAlgorithms/C-Plus-Plus `math/ncr_modulo_p.cpp` at commit [`fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/ncr_modulo_p.cpp). The additional C-Plus-Plus-1 copy is not used as the contract source: it allocates a factorial vector with `size` elements and writes `fac[size]`, an out-of-bounds access.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm ncr_modulo_p --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/ncr_modulo_p/rust/build.json
```

The `i64_array_scalar` runner validates the packed bounds and checks the source's factorial table, shortcut order, and extended-Euclid result.

## Workload and implementations

The workload covers ordinary values, each query shortcut, `r > n`, and noninvertible denominators under composite moduli. All nine ports use the existing `i64_array_scalar` ABI.

| Language | Implementation |
| --- | --- |
| C | [`c/n/ncr_modulo_p.c`](../../../c/n/ncr_modulo_p.c) |
| C3 | [`c3/n/ncr_modulo_p.c3`](../../../c3/n/ncr_modulo_p.c3) |
| C++ | [`cpp/n/ncr_modulo_p.cpp`](../../../cpp/n/ncr_modulo_p.cpp) |
| Elisa | [`elisa/n/ncr_modulo_p.elisa`](../../../elisa/n/ncr_modulo_p.elisa) |
| Nim | [`nim/n/ncr_modulo_p.nim`](../../../nim/n/ncr_modulo_p.nim) |
| Odin | [`odin/n/ncr_modulo_p.odin`](../../../odin/n/ncr_modulo_p.odin) |
| Rust | [`rust/n/ncr_modulo_p.rs`](../../../rust/n/ncr_modulo_p.rs) |
| V | [`v/n/ncr_modulo_p.v`](../../../v/n/ncr_modulo_p.v) |
| Zig | [`zig/n/ncr_modulo_p.zig`](../../../zig/n/ncr_modulo_p.zig) |

