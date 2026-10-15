# All subsequences

This benchmark follows the pinned Python `generate_all_subsequences` routine. It recursively explores the branch that skips the current input position before the branch that includes it, and emits a subsequence only at a leaf. Equal values at distinct input positions remain distinct choices, so duplicate output rows are retained.

## Contract

- The packed input is `[n, values...]`, where `n` is from 0 through 8 and there are exactly `n` signed 32-bit values.
- Output has `2^n` rows in skip-before-include depth-first order. Each row is encoded as a little-endian unsigned 32-bit length followed by that many little-endian signed 32-bit values. For `n=0`, one empty row is emitted and occupies four bytes.
- The return value is the number of rows. A malformed packed input or a value outside signed 32-bit range returns `-1`; insufficient output capacity returns `-2`.
- At the maximum `n=8`, output has 256 rows and 5,120 bytes. Runtime is O(n × 2^n); working state is O(n).

The Python source prints each subsequence rather than returning an array; the benchmark captures those rows in a length-prefixed byte buffer. It preserves the source's traversal order and does not deduplicate equal values. This is distinct from permutation generation, which reorders positions.

[`workload.json`](workload.json) covers the empty and singleton cases, source traversal order, duplicate values, signed boundaries, the maximum input size, and malformed input cases.

| Language | Source |
| --- | --- |
| C | [`c/a/all_subsequences.c`](../../../c/a/all_subsequences.c) |
| C3 | [`c3/a/all_subsequences.c3`](../../../c3/a/all_subsequences.c3) |
| C++ | [`cpp/a/all_subsequences.cpp`](../../../cpp/a/all_subsequences.cpp) |
| Elisa | [`elisa/a/all_subsequences.elisa`](../../../elisa/a/all_subsequences.elisa) |
| Nim | [`nim/a/all_subsequences.nim`](../../../nim/a/all_subsequences.nim) |
| Odin | [`odin/a/all_subsequences.odin`](../../../odin/a/all_subsequences.odin) |
| Rust | [`rust/a/all_subsequences.rs`](../../../rust/a/all_subsequences.rs) |
| V | [`v/a/all_subsequences.v`](../../../v/a/all_subsequences.v) |
| Zig | [`zig/a/all_subsequences.zig`](../../../zig/a/all_subsequences.zig) |

Pinned source: [TheAlgorithms/Python `all_subsequences.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/all_subsequences.py).
