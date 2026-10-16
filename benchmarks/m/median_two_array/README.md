# Median of two sorted arrays

Return the median of the union of two individually sorted integer arrays.

## Contract

The `i64_array_float64` input is `[n1, n2, first_array..., second_array...]`. The total number of elements is 1–256; each array must be nondecreasing, and values are from -1,000,000 through 1,000,000. Odd totals return the middle value as binary64; even totals return the average of the two middle values. Empty union, malformed lengths, unsorted arrays, and out-of-range values return `-1e300`.

## Source semantics

This follows the pinned [TheAlgorithms Python `median_two_array.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/median_two_array.py), which concatenates and sorts both arrays, raises when both are empty, returns a float for odd totals, and averages the center pair for even totals. The benchmark uses a bounded integer subset. Its ports validate the sorted-input precondition and sort the combined data before selecting the center value(s).

The independent oracle is [`median_two_array_oracle.py`](../../median_two_array_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/median_two_array.c](../../../c/m/median_two_array.c) |
| C3 | [c3/m/median_two_array.c3](../../../c3/m/median_two_array.c3) |
| C++ | [cpp/m/median_two_array.cpp](../../../cpp/m/median_two_array.cpp) |
| Elisa | [elisa/m/median_two_array.elisa](../../../elisa/m/median_two_array.elisa) |
| Nim | [nim/m/median_two_array.nim](../../../nim/m/median_two_array.nim) |
| Odin | [odin/m/median_two_array.odin](../../../odin/m/median_two_array.odin) |
| Rust | [rust/m/median_two_array.rs](../../../rust/m/median_two_array.rs) |
| V | [v/m/median_two_array.v](../../../v/m/median_two_array.v) |
| Zig | [zig/m/median_two_array.zig](../../../zig/m/median_two_array.zig) |

The package uses the `i64_array_float64` benchmark ABI.
