# `link_list_sort` bounded three-selector sort

This benchmark follows the pinned Java `LinkListSort.isSorted` method. Selector 1 builds a linked list and applies merge sort, selector 2 uses linked-list insertion sort, and selector 3 uses linked-list heap sort. Each branch copies its sorted values back into the original `int[]`.

The Java method's boolean is omitted from the benchmark output. Its local arrays `a` and `b` both reference `p`, so the comparison returns `true` for every valid selector after the in-place sort. The measured result is the sorted array state, encoded as little-endian signed 32-bit values.

## Contract

- Input is `[selector, item_count, value_0, ...]` in the signed 64-bit array ABI. Selector 1 is merge sort, 2 is insertion sort, and 3 is heap sort.
- Item count is 0 through 128. Values must fit signed 32-bit integers. The maximum input length is 130 values.
- An empty array is valid for all three selectors and produces zero output bytes.
- Invalid framing, selector, item count, out-of-range values, and null input return `-1` before output-buffer checks.
- Successful calls return the output byte count. A null output pointer or insufficient capacity returns `-2` without writing; even an empty result requires a non-null output pointer with capacity 0.
- The maximum output is 128 signed 32-bit values (512 bytes).

The workload includes each selector, empty and singleton arrays, duplicates, sorted and reverse-ordered data, signed 32-bit boundaries, the maximum input/output size, malformed inputs, null output, exact and short nonempty output capacities, and the empty-output zero-capacity boundary. The independent [oracle](../../link_list_sort_oracle.py) sorts the selected values and checks the published byte result.

Pinned source: [TheAlgorithms/Java `LinkListSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/LinkListSort.java).

## Language ports

| Language | Source |
|---|---|
| C | [c/l/link_list_sort.c](../../../c/l/link_list_sort.c) |
| C3 | [c3/l/link_list_sort.c3](../../../c3/l/link_list_sort.c3) |
| C++ | [cpp/l/link_list_sort.cpp](../../../cpp/l/link_list_sort.cpp) |
| Elisa | [elisa/l/link_list_sort.elisa](../../../elisa/l/link_list_sort.elisa) |
| Nim | [nim/l/link_list_sort.nim](../../../nim/l/link_list_sort.nim) |
| Odin | [odin/l/link_list_sort.odin](../../../odin/l/link_list_sort.odin) |
| Rust | [rust/l/link_list_sort.rs](../../../rust/l/link_list_sort.rs) |
| V | [v/l/link_list_sort.v](../../../v/l/link_list_sort.v) |
| Zig | [zig/l/link_list_sort.zig](../../../zig/l/link_list_sort.zig) |
