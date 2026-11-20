# Fermat factorization

This package benchmarks bounded Fermat factor search for an odd integer. It starts at the least integer `a` with `a² >= N` and checks successive values for a square difference `a²-N=b²`. Such a hit gives factors `a-b` and `a+b`; the function returns the first proper positive factor `a-b`.

## Contract

The `i64_array_scalar` input is `[N,max_steps]`. `N` must be odd and in `3..1,000,000,000,000`; `max_steps` is in `0..4096`. Exactly `max_steps` candidates are inspected, beginning at `ceil(sqrt(N))`. A candidate whose difference is a square contributes a result only when `1 < a-b < N`; the trivial factor pair `(1,N)` is skipped. Return `0` when the bounded search finds no proper factor, and `-1` for malformed or out-of-profile input. Valid and parseable input lengths are 2 and 3 i64 values.

The ports use exact integer square-root checks. Their fixed-width intermediates remain below signed 64-bit limits under the declared number and step bounds. The primary reference mirrors the bounded square-difference search. The independent reference enumerates factor pairs from the square-root side and checks the nearest-pair distance against the search budget. The primary takes `O(max_steps * log N)` arithmetic steps with binary-search square roots and `O(1)` auxiliary space; the independent reference takes `O(sqrt(N))` trial divisions.

## Provenance and rights

The clean-room implementation follows the algorithm description in [CP-Algorithms — Fermat's factorization method](https://cp-algorithms.com/algebra/factorization.html#fermats-factorization-method). CP-Algorithms is licensed CC BY-SA 4.0. This package uses the mathematical method only; no source code, article prose, examples, or tasks were copied. See [`RIGHTS.md`](RIGHTS.md) and [`workload.json`](workload.json).

## Language ports

| Language | Source |
|---|---|
| C | [`fermat_factorization.c`](../../../c/f/fermat_factorization.c) |
| C3 | [`fermat_factorization.c3`](../../../c3/f/fermat_factorization.c3) |
| C++ | [`fermat_factorization.cpp`](../../../cpp/f/fermat_factorization.cpp) |
| Elisa | [`fermat_factorization.elisa`](../../../elisa/f/fermat_factorization.elisa) |
| Mojo | [`fermat_factorization.mojo`](../../../mojo/f/fermat_factorization.mojo) |
| Nim | [`fermat_factorization.nim`](../../../nim/f/fermat_factorization.nim) |
| Odin | [`fermat_factorization.odin`](../../../odin/f/fermat_factorization.odin) |
| Rust | [`fermat_factorization.rs`](../../../rust/f/fermat_factorization.rs) |
| V | [`fermat_factorization.v`](../../../v/f/fermat_factorization.v) |
| Zig | [`fermat_factorization.zig`](../../../zig/f/fermat_factorization.zig) |

The shared `i64_array_scalar` runner and verifier register the workload. No programs or checks have been run.
