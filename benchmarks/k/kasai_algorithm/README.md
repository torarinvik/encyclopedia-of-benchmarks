# Kasai Algorithm

This package follows the pinned Java [`KasaiAlgorithm.kasai`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/KasaiAlgorithm.java), which computes the longest common prefix (LCP) lengths of adjacent suffixes from a supplied suffix array.

## Contract

The `i64_array_scalar` input is exactly `[n, text[0..n), suffix_array[0..n)]`, with `0 <= n <= 512`. Each text value is an ASCII byte in `[0,127]`. The suffix array must contain every index in `[0,n)` exactly once and be sorted lexicographically by the corresponding suffix. Any invalid count, shape, text byte, or suffix array returns `-1`.

After building inverse ranks, the ports validate adjacent suffix order in O(n) by comparing each suffix's first byte and the rank of its one-byte tail (using rank `-1` for the empty tail). Kasai's LCP pass is also O(n); the ports do not repeatedly compare whole suffixes in the timed path.

For each `rank` from `0` through `n-2`, `LCP[rank]` is the common-prefix length of the suffixes starting at `suffix_array[rank]` and `suffix_array[rank+1]`. `LCP[n-1]` is zero. When `n=0`, the LCP array is empty.

The scalar result is the low 63 bits of FNV-1a-64 over the signed-i64 little-endian words `[n, LCP[0], ..., LCP[n-1]]`, using offset basis `14695981039346656037` and prime `1099511628211`. The independent oracle is [`kasai_algorithm_oracle.py`](../../kasai_algorithm_oracle.py); the workload is [`workload.json`](workload.json).

## Implementations

| Language | Port |
|---|---|
| C | [`c/k/kasai_algorithm.c`](../../../c/k/kasai_algorithm.c) |
| C3 | [`c3/k/kasai_algorithm.c3`](../../../c3/k/kasai_algorithm.c3) |
| C++ | [`cpp/k/kasai_algorithm.cpp`](../../../cpp/k/kasai_algorithm.cpp) |
| Elisa | [`elisa/k/kasai_algorithm.elisa`](../../../elisa/k/kasai_algorithm.elisa) |
| Nim | [`nim/k/kasai_algorithm.nim`](../../../nim/k/kasai_algorithm.nim) |
| Odin | [`odin/k/kasai_algorithm.odin`](../../../odin/k/kasai_algorithm.odin) |
| Rust | [`rust/k/kasai_algorithm.rs`](../../../rust/k/kasai_algorithm.rs) |
| V | [`v/k/kasai_algorithm.v`](../../../v/k/kasai_algorithm.v) |
| Zig | [`zig/k/kasai_algorithm.zig`](../../../zig/k/kasai_algorithm.zig) |

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm kasai_algorithm --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/k/kasai_algorithm/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithm kasai_algorithm --languages rust
```
