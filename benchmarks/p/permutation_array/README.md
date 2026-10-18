# Array permutation enumeration

This benchmark follows the pinned Java `Permutation.permutation` routine. It
clones the input, recursively swaps each remaining position into the current
slot, and appends a clone at each leaf. Equal values at different input
positions are separate choices, so duplicate rows are retained.

## Contract

- Input is `[n, values...]`, where `n` is from 0 through 6 and there are exactly
  `n` signed 32-bit values.
- Inputs longer than 8 words are rejected before reading the count; an 8-word
  input with `n=7` is parsed and rejected as outside the bounded domain.
- Output contains `n!` rows in the Java swap-recursion order. Each row contains
  `n` little-endian signed 32-bit values. For `n=0`, the source appends one
  empty row, so the result is 1 and the output contains zero bytes.
- The return value is the number of rows. Malformed framing or a value outside
  signed 32-bit range returns `-1`. A null output pointer for nonempty output,
  or insufficient output capacity, returns `-2` without writing. Input
  validation precedes output-buffer checks; a null pointer is accepted when
  the output is empty.
- At the maximum `n=6`, the source emits 720 rows and at most 17,280 output
  bytes. Runtime is O(n × n!) and the working state is O(n), excluding output.

This is distinct from [`all_permutations`](../../a/all_permutations/README.md),
which chooses unused input indices and therefore has a different traversal
order for some inputs. It is also distinct from the C# string permutation
variant, which deduplicates equal strings.

[`workload.json`](workload.json) covers the empty and singleton arrays, an
ordering example, duplicate rows, signed boundaries, the maximum output,
malformed inputs, and output-capacity errors. The independent oracle is
[`permutation_array_oracle.py`](../../permutation_array_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/permutation_array.c`](../../../c/p/permutation_array.c) |
| C3 | [`c3/p/permutation_array.c3`](../../../c3/p/permutation_array.c3) |
| C++ | [`cpp/p/permutation_array.cpp`](../../../cpp/p/permutation_array.cpp) |
| Elisa | [`elisa/p/permutation_array.elisa`](../../../elisa/p/permutation_array.elisa) |
| Nim | [`nim/p/permutation_array.nim`](../../../nim/p/permutation_array.nim) |
| Odin | [`odin/p/permutation_array.odin`](../../../odin/p/permutation_array.odin) |
| Rust | [`rust/p/permutation_array.rs`](../../../rust/p/permutation_array.rs) |
| V | [`v/p/permutation_array.v`](../../../v/p/permutation_array.v) |
| Zig | [`zig/p/permutation_array.zig`](../../../zig/p/permutation_array.zig) |

## Pinned source

- [TheAlgorithms/Java `Permutation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/Permutation.java)
