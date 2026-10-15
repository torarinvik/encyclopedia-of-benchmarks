# All permutations

This benchmark follows the pinned Python `generate_all_permutations` routine. It emits every ordering of the input by recursively choosing unused input positions from left to right. Equal values at different positions remain distinct choices, so duplicate rows are retained. The operation writes the permutations in order and does not modify the input.

## Contract

- The packed input is `[n, values...]`, where `n` is from 0 through 6 and there are exactly `n` signed 32-bit values.
- Output contains `n!` rows in depth-first input-index order. Each row contains `n` little-endian signed 32-bit values. For `n=0`, there is one empty permutation: the result count is 1 and the output has zero bytes.
- The return value is the number of rows. A malformed packed input or a value outside signed 32-bit range returns `-1`; insufficient output capacity returns `-2`.
- At the maximum `n=6`, output is 720 rows and 17,280 bytes. Runtime is O(n × n!) and the working state is O(n).

The source [prints each permutation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/all_permutations.py) rather than returning an array; this benchmark captures the same rows and order in a packed byte buffer. Its traversal does not deduplicate repeated values. Other repository implementations use swap traversal or deduplicate equal values, so their row order or row count can differ. This operation is distinct from [`permutation_in_string`](../../p/permutation_in_string/README.md), which only checks for a pattern inside a string.

[`workload.json`](workload.json) includes empty and singleton inputs, traversal-order examples, repeated values, signed boundaries, the maximum supported size, and malformed input cases.

| Language | Source |
| --- | --- |
| C | [`c/a/all_permutations.c`](../../../c/a/all_permutations.c) |
| C3 | [`c3/a/all_permutations.c3`](../../../c3/a/all_permutations.c3) |
| C++ | [`cpp/a/all_permutations.cpp`](../../../cpp/a/all_permutations.cpp) |
| Elisa | [`elisa/a/all_permutations.elisa`](../../../elisa/a/all_permutations.elisa) |
| Nim | [`nim/a/all_permutations.nim`](../../../nim/a/all_permutations.nim) |
| Odin | [`odin/a/all_permutations.odin`](../../../odin/a/all_permutations.odin) |
| Rust | [`rust/a/all_permutations.rs`](../../../rust/a/all_permutations.rs) |
| V | [`v/a/all_permutations.v`](../../../v/a/all_permutations.v) |
| Zig | [`zig/a/all_permutations.zig`](../../../zig/a/all_permutations.zig) |
