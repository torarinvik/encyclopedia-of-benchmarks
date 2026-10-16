# Permutation and combination

The pinned JavaScript module exports recursive factorial, permutation, and combination functions. It computes `n!`, `n!/(n-r)!`, and `n!/(r!(n-r)!)` respectively.

## Contract

Input is `[operation, n, r]`: operation 0 selects factorial, 1 permutation, and 2 combination. `n` is from 0 through 18; the second argument is ignored for factorial and must satisfy `0 <= r <= n` for the other operations. Invalid inputs return `-1`. The bound keeps all integer results exactly representable in JavaScript's Number type.

See [`workload.json`](workload.json) and the runtime [oracle](../../permutation_and_combination_oracle.py). Pinned source: [TheAlgorithms/JavaScript `PermutationAndCombination.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PermutationAndCombination.js).

| Language | Port |
|---|---|
| C | [`c/p/permutation_and_combination.c`](../../../c/p/permutation_and_combination.c) |
| C3 | [`c3/p/permutation_and_combination.c3`](../../../c3/p/permutation_and_combination.c3) |
| C++ | [`cpp/p/permutation_and_combination.cpp`](../../../cpp/p/permutation_and_combination.cpp) |
| Elisa | [`elisa/p/permutation_and_combination.elisa`](../../../elisa/p/permutation_and_combination.elisa) |
| Nim | [`nim/p/permutation_and_combination.nim`](../../../nim/p/permutation_and_combination.nim) |
| Odin | [`odin/p/permutation_and_combination.odin`](../../../odin/p/permutation_and_combination.odin) |
| Rust | [`rust/p/permutation_and_combination.rs`](../../../rust/p/permutation_and_combination.rs) |
| V | [`v/p/permutation_and_combination.v`](../../../v/p/permutation_and_combination.v) |
| Zig | [`zig/p/permutation_and_combination.zig`](../../../zig/p/permutation_and_combination.zig) |
