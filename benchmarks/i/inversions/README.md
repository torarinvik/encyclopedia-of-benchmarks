# Inversion count

Count out-of-order pairs in an integer sequence using the pinned Python module's brute-force helper.

## Contract

The `i64_array_scalar` ABI accepts zero through 1,024 signed 32-bit integers and returns the number of pairs `(i, j)` for which `i < j` and `values[i] > values[j]`. Equal values do not form inversions, and the input is not modified. Invalid length or values return `-1`. The selected source helper takes O(n²) time and O(1) auxiliary space.

[`workload.json`](workload.json) covers empty, sorted, descending, duplicate, and negative-valued sequences.

Pinned source: [TheAlgorithms/Python `inversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/inversions.py). The source also provides a divide-and-conquer variant; this benchmark isolates `count_inversions_bf`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/inversions.c`](../../../c/i/inversions.c) |
| C3 | [`c3/i/inversions.c3`](../../../c3/i/inversions.c3) |
| C++ | [`cpp/i/inversions.cpp`](../../../cpp/i/inversions.cpp) |
| Elisa | [`elisa/i/inversions.elisa`](../../../elisa/i/inversions.elisa) |
| Nim | [`nim/i/inversions.nim`](../../../nim/i/inversions.nim) |
| Odin | [`odin/i/inversions.odin`](../../../odin/i/inversions.odin) |
| Rust | [`rust/i/inversions.rs`](../../../rust/i/inversions.rs) |
| V | [`v/i/inversions.v`](../../../v/i/inversions.v) |
| Zig | [`zig/i/inversions.zig`](../../../zig/i/inversions.zig) |
