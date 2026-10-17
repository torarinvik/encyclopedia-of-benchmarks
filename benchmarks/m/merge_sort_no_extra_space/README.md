# Merge sort without extra merge space

## Contract

Sort a sequence of signed 32-bit integers in ascending order using recursive in-place merge sort. The supported input is an array of 0–256 values, each in `0..=32767`; negative values are rejected by the pinned implementation, and the value bound keeps its `maxElement = max + 1` encoding within signed 32-bit range. Empty and single-element arrays are returned unchanged. The algorithm is not stable as a public guarantee.

The source merge stores each newly selected value in the high part of an existing element while preserving the old value in the low part, then divides every merged element by `maxElement` to restore the sorted values. With `maxElement <= 32768`, each encoded cell is at most `32767 + 32767 * 32768 = 1,073,741,823`, below `INT32_MAX`. The merge uses no auxiliary element buffer; recursion uses logarithmic stack space.

The C ABI entry point is:

```c
int64_t merge_sort_no_extra_space(const int32_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity);
```

Input is a direct signed-32-bit array. A nonnull empty input is valid and returns zero output bytes. A null input, length above 256, or value outside `0..32767` returns `-1`. Valid output is the sorted array encoded as little-endian signed-32-bit elements and the function returns `4 * length`. A null output pointer or insufficient capacity returns `-2`; validation errors take precedence, and errors write no output. The implementation sorts the encoded result buffer in place, so it does not allocate a merge buffer.

## Workload

[`workload.json`](workload.json) covers empty and singleton arrays, sorted and reverse order, duplicates, all-zero and maximum-value inputs, a 256-element generated case, malformed lengths and values, null input/output, and insufficient capacity. The recorder uses the `i32_array_bytes_output` family and compares the complete little-endian output.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/merge_sort_no_extra_space.c`](../../../c/m/merge_sort_no_extra_space.c) |
| C3 | [`c3/m/merge_sort_no_extra_space.c3`](../../../c3/m/merge_sort_no_extra_space.c3) |
| C++ | [`cpp/m/merge_sort_no_extra_space.cpp`](../../../cpp/m/merge_sort_no_extra_space.cpp) |
| Elisa | [`elisa/m/merge_sort_no_extra_space.elisa`](../../../elisa/m/merge_sort_no_extra_space.elisa) |
| Nim | [`nim/m/merge_sort_no_extra_space.nim`](../../../nim/m/merge_sort_no_extra_space.nim) |
| Odin | [`odin/m/merge_sort_no_extra_space.odin`](../../../odin/m/merge_sort_no_extra_space.odin) |
| Rust | [`rust/m/merge_sort_no_extra_space.rs`](../../../rust/m/merge_sort_no_extra_space.rs) |
| V | [`v/m/merge_sort_no_extra_space.v`](../../../v/m/merge_sort_no_extra_space.v) |
| Zig | [`zig/m/merge_sort_no_extra_space.zig`](../../../zig/m/merge_sort_no_extra_space.zig) |

## TheAlgorithms source

- [Java `MergeSortNoExtraSpace.java` at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/MergeSortNoExtraSpace.java)
