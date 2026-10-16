# Simple modular inverse

Compute the multiplicative inverse of `x` modulo `y` with the pinned source's iterative search: increase `itr` from zero until `y * itr + 1` is divisible by `x`, then return `(y * itr + 1) / x`. This is a distinct brute-force strategy from [`modular_inverse`](../modular_inverse/README.md), which uses extended Euclid, and [`modular_inverse_fermat_little_theorem`](../modular_inverse_fermat_little_theorem/README.md), which uses primality testing and binary exponentiation.

## Contract

- The `binary_scalar` input is `[x, y]`, matching the source's `imod(x, y)` order.
- `x` is in `[1, 999]`; `y` is in `[2, 1,000]`; `gcd(x, y)` must equal 1.
- A valid input returns the least positive `z` satisfying `(x * z) mod y == 1`. Invalid bounds and non-coprime pairs return `-1`.
- The source loops forever when no inverse exists, so the ports check coprimality before entering the source's iterative search.
- For `x > 1`, the search finds a solution with `itr <= x - 1`; thus `y * itr + 1 <= 998,001`. For `x == 1`, the first candidate returns 1. All intermediate values fit signed 64-bit.

## Workload and oracle

[`workload.json`](workload.json) includes the three pinned examples, small and maximum-bound inputs, and invalid or non-coprime pairs. The independent oracle uses modular arithmetic directly: [`modular_inverse_simple_oracle.py`](../../modular_inverse_simple_oracle.py).

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `modular_inverse_simple.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/modular_inverse_simple.cpp)
- [TheAlgorithms/C-Plus-Plus-1 duplicate](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/modular_inverse_simple.cpp)

The two pinned `imod()` function bodies are identical. They take unsigned arguments, search successive values of `itr`, and return the quotient once the numerator is divisible by `x`.

## Build and record

    python3 benchmarks/build_abi.py --family binary_scalar --algorithm modular_inverse_simple --language rust
    python3 benchmarks/run_binary_scalar.py --algorithm modular_inverse_simple
    python3 benchmarks/verify_binary_scalar.py --algorithms modular_inverse_simple

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/modular_inverse_simple.c`](../../../c/m/modular_inverse_simple.c) |
| C3 | [`c3/m/modular_inverse_simple.c3`](../../../c3/m/modular_inverse_simple.c3) |
| C++ | [`cpp/m/modular_inverse_simple.cpp`](../../../cpp/m/modular_inverse_simple.cpp) |
| Elisa | [`elisa/m/modular_inverse_simple.elisa`](../../../elisa/m/modular_inverse_simple.elisa) |
| Nim | [`nim/m/modular_inverse_simple.nim`](../../../nim/m/modular_inverse_simple.nim) |
| Odin | [`odin/m/modular_inverse_simple.odin`](../../../odin/m/modular_inverse_simple.odin) |
| Rust | [`rust/m/modular_inverse_simple.rs`](../../../rust/m/modular_inverse_simple.rs) |
| V | [`v/m/modular_inverse_simple.v`](../../../v/m/modular_inverse_simple.v) |
| Zig | [`zig/m/modular_inverse_simple.zig`](../../../zig/m/modular_inverse_simple.zig) |
