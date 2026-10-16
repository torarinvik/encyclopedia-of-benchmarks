# K-th lexicographic permutation

This benchmark ports the pinned Python factoradic selection routine for permutations of `0..n-1`. The source uses a zero-based rank `k`, selects digits by factorial blocks, and removes each selected element. The benchmark encodes the returned full permutation as decimal digits: first `n`, then each element plus one.

## Contract

Input is `[k, n]`, with `2 <= n <= 9` and `0 <= k < n!`. The source has an edge-case failure at `n=1`, so that value is excluded. Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../kth_lexicographic_permutation_oracle.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/kth_lexicographic_permutation.py).

| Language | Port |
|---|---|
| C | [`c/k/kth_lexicographic_permutation.c`](../../../c/k/kth_lexicographic_permutation.c) |
| C3 | [`c3/k/kth_lexicographic_permutation.c3`](../../../c3/k/kth_lexicographic_permutation.c3) |
| C++ | [`cpp/k/kth_lexicographic_permutation.cpp`](../../../cpp/k/kth_lexicographic_permutation.cpp) |
| Elisa | [`elisa/k/kth_lexicographic_permutation.elisa`](../../../elisa/k/kth_lexicographic_permutation.elisa) |
| Nim | [`nim/k/kth_lexicographic_permutation.nim`](../../../nim/k/kth_lexicographic_permutation.nim) |
| Odin | [`odin/k/kth_lexicographic_permutation.odin`](../../../odin/k/kth_lexicographic_permutation.odin) |
| Rust | [`rust/k/kth_lexicographic_permutation.rs`](../../../rust/k/kth_lexicographic_permutation.rs) |
| V | [`v/k/kth_lexicographic_permutation.v`](../../../v/k/kth_lexicographic_permutation.v) |
| Zig | [`zig/k/kth_lexicographic_permutation.zig`](../../../zig/k/kth_lexicographic_permutation.zig) |
