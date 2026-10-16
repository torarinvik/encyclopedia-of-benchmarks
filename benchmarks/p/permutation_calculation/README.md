# Permutation calculation

The pinned R `calculate_permutations(n, r)` returns the number of arrangements of `r` objects selected from `n`, using the factorial ratio `n! / (n-r)!`. It explicitly defines zero factorial as 1 and rejects `r > n`.

## Contract

Input is `[n, r]`, with `0 <= r <= n <= 15`. The bound keeps both factorials and the quotient exactly representable in the pinned R numeric arithmetic and signed 64-bit outputs. Invalid inputs return `-1`.

See [`workload.json`](workload.json) and the runtime [oracle](../../permutation_calculation_oracle.py). Pinned source: [TheAlgorithms/R `permutation_calculation.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/permutation_calculation.r).

| Language | Port |
|---|---|
| C | [`c/p/permutation_calculation.c`](../../../c/p/permutation_calculation.c) |
| C3 | [`c3/p/permutation_calculation.c3`](../../../c3/p/permutation_calculation.c3) |
| C++ | [`cpp/p/permutation_calculation.cpp`](../../../cpp/p/permutation_calculation.cpp) |
| Elisa | [`elisa/p/permutation_calculation.elisa`](../../../elisa/p/permutation_calculation.elisa) |
| Nim | [`nim/p/permutation_calculation.nim`](../../../nim/p/permutation_calculation.nim) |
| Odin | [`odin/p/permutation_calculation.odin`](../../../odin/p/permutation_calculation.odin) |
| Rust | [`rust/p/permutation_calculation.rs`](../../../rust/p/permutation_calculation.rs) |
| V | [`v/p/permutation_calculation.v`](../../../v/p/permutation_calculation.v) |
| Zig | [`zig/p/permutation_calculation.zig`](../../../zig/p/permutation_calculation.zig) |
