# Is sorted

Check whether a numeric array is sorted in nondecreasing order. The benchmark follows the pinned Lua source's default numeric `less_than` comparator and adjacent-pair scan. It accepts empty and singleton arrays.

## Contract

- ABI: `i64_array_scalar`; each array element is one signed 32-bit integer.
- The array length is between 0 and 4,096.
- Return `1` when every adjacent pair satisfies `values[i - 1] <= values[i]`; otherwise return `0`.
- Return `-1` for a length above 4,096, a null nonempty input, or an element outside the signed 32-bit range.

The pinned Lua source also accepts a caller-provided comparator; this benchmark uses its default numeric `<` comparator. The same-name Python source checks whether a binary tree is a valid BST. That is a separate algorithm and is not mapped to this array contract.

[`workload.json`](workload.json) covers empty and singleton arrays, sorted values, duplicates, descending input, a local inversion, signed 32-bit boundaries, invalid values, and the maximum length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_sorted.c`](../../../c/i/is_sorted.c) |
| C3 | [`c3/i/is_sorted.c3`](../../../c3/i/is_sorted.c3) |
| C++ | [`cpp/i/is_sorted.cpp`](../../../cpp/i/is_sorted.cpp) |
| Elisa | [`elisa/i/is_sorted.elisa`](../../../elisa/i/is_sorted.elisa) |
| Nim | [`nim/i/is_sorted.nim`](../../../nim/i/is_sorted.nim) |
| Odin | [`odin/i/is_sorted.odin`](../../../odin/i/is_sorted.odin) |
| Rust | [`rust/i/is_sorted.rs`](../../../rust/i/is_sorted.rs) |
| V | [`v/i/is_sorted.v`](../../../v/i/is_sorted.v) |
| Zig | [`zig/i/is_sorted.zig`](../../../zig/i/is_sorted.zig) |

## Pinned sources

- The PHP [`ArrayHelpers.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Utils/ArrayHelpers.php) helper checks nondecreasing order; this benchmark normalizes its exception to false.
- [Lua `src/sorting/is_sorted.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/sorting/is_sorted.lua)
- [Python `data_structures/binary_tree/is_sorted.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/is_sorted.py) is the distinct BST-validation source.
