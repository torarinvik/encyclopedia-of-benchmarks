# Arithmetic derivative

This package computes the arithmetic derivative, the integer derivation that imitates the product rule. Its defining values are `D(0)=D(1)=0`, `D(p)=1` for every prime, and `D(ab)=aD(b)+bD(a)`.

## Contract

- ABI: `i64_array_scalar`; symbol: `arithmetic_derivative`.
- Input is exactly `[n]`, with `0<=n<=1,000,000,000,000`. The parseable frame cap is two words so a trailing word is rejected explicitly.
- Return `D(n)`; malformed or out-of-domain input returns `-1`.
- For `n=∏p^e`, the primary uses `D(n)=n∑(e/p)`, adding `(original_n/p)*e` per distinct prime factor. The independent reference recursively applies the product rule to `n=pq` as `D(n)=pD(q)+q`.
- For `n>=1`, each prime is at least 2 and `Ω(n)=∑e<=floor(log2(n))`, so `D(n)<=n*floor(log2(n))/2`; with `D(0)=0`, valid results are at most 19,500,000,000,000 and fit i64.
- The primary checks at most 500,000 candidate divisors through `sqrt(n)` at the input cap, with fewer than 64 bytes of explicit scalar state; the declared native workspace cap is 256 bytes. The independent recursion has at most 39 product-rule steps, each doing at most 500,000 least-factor candidates (at most 19.5 million total), or 40 stack frames including the base call.

The workload covers zero and one, primes, prime powers, products of coprime values, mixed exponents, the maximum input, malformed frames, and signed-i64 boundaries. `D(10^12)=8,400,000,000,000`.

This operation differs from [`mobius_function`](../../m/mobius_function/README.md), [`liouville_lambda`](../../l/liouville_lambda/README.md), [`euler_totient`](../../e/euler_totient/README.md), divisor-count functions, and factorization packages: it computes the product-rule derivation itself.

## Source and provenance

E. J. Barbeau defines the arithmetic derivative by `D(0)=D(1)=0`, `D(p)=1` for primes, and the product rule in “Remarks on an Arithmetic Derivative,” *Canadian Mathematical Bulletin* 4(2) (1961), 117–122 ([DOI 10.4153/CMB-1961-013-0](https://doi.org/10.4153/CMB-1961-013-0)). The [RosettaCodeData popular-tasks index](https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks) was used only to discover the title. No Rosetta task text, code, or fixtures were used.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/a/arithmetic_derivative.c`](../../../c/a/arithmetic_derivative.c) |
| C3 | [`c3/a/arithmetic_derivative.c3`](../../../c3/a/arithmetic_derivative.c3) |
| C++ | [`cpp/a/arithmetic_derivative.cpp`](../../../cpp/a/arithmetic_derivative.cpp) |
| Elisa | [`elisa/a/arithmetic_derivative.elisa`](../../../elisa/a/arithmetic_derivative.elisa) |
| Mojo | [`mojo/a/arithmetic_derivative.mojo`](../../../mojo/a/arithmetic_derivative.mojo) |
| Nim | [`nim/a/arithmetic_derivative.nim`](../../../nim/a/arithmetic_derivative.nim) |
| Odin | [`odin/a/arithmetic_derivative.odin`](../../../odin/a/arithmetic_derivative.odin) |
| Rust | [`rust/a/arithmetic_derivative.rs`](../../../rust/a/arithmetic_derivative.rs) |
| V | [`v/a/arithmetic_derivative.v`](../../../v/a/arithmetic_derivative.v) |
| Zig | [`zig/a/arithmetic_derivative.zig`](../../../zig/a/arithmetic_derivative.zig) |

The package workload is paired with `primary_oracle.py` and `independent_oracle.py` through `verify_workload.py`. `check_inventory.py` statically pins package artifacts, language paths, exported symbols, null guards, and documentation links. The scalar runner and verifier plus README and CATALOG entries are integrated; no static helper or benchmark was run.
