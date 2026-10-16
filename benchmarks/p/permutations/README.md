# Integer permutations

This benchmark follows the pinned Python `permute_backtrack` routine called by the module's main block and the Rust `permute` routine. Both generate a permutation list with backtracking.

## Contract

- Input is `[count, values...]`, where `count` is 1 through 6 and values are strictly increasing signed 32-bit integers.
- The result is 32-bit FNV-1a over the lexicographically ordered permutation list. Each signed-i32 value is serialized little-endian, and each permutation ends with byte `0xFF`.
- Invalid, empty, duplicate, or unsorted input returns `-1`.

The Python implementation emits DFS swap order based on input order; the Rust implementation sorts first and suppresses duplicate choices. On the contract's sorted, distinct input domain both produce the same lexicographic list. The source files also contain Python's separate `permute_recursive` variant, which is not the entry point called by its main block. The hash maps the result list to the scalar-array ABI.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/permutations.c`](../../../c/p/permutations.c) |
| C3 | [`c3/p/permutations.c3`](../../../c3/p/permutations.c3) |
| C++ | [`cpp/p/permutations.cpp`](../../../cpp/p/permutations.cpp) |
| Elisa | [`elisa/p/permutations.elisa`](../../../elisa/p/permutations.elisa) |
| Nim | [`nim/p/permutations.nim`](../../../nim/p/permutations.nim) |
| Odin | [`odin/p/permutations.odin`](../../../odin/p/permutations.odin) |
| Rust | [`rust/p/permutations.rs`](../../../rust/p/permutations.rs) |
| V | [`v/p/permutations.v`](../../../v/p/permutations.v) |
| Zig | [`zig/p/permutations.zig`](../../../zig/p/permutations.zig) |

## Workload and recording

[`workload.json`](workload.json) covers one through six values and invalid domains. The runtime oracle is [`permutations_oracle.py`](../../permutations_oracle.py); the array-scalar runner checks each expected hash before recording.

## Pinned sources

- [Python `permutations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/permutations.py)
- [Rust `permutations.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/backtracking/permutations.rs)
