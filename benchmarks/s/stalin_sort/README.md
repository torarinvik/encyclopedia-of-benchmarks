# stalin_sort

This benchmark follows the pinned [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/stalin_sort.py) and [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/StalinSort.java) implementations. Both retain the first value, then retain each later value when it is greater than or equal to the last retained value. Equal values are kept. The Java implementation compacts the supplied array before copying the retained prefix; Python builds a new list. The benchmark compares the returned sequence and does not expose that source-specific mutation detail through its ABI.

## Contract

The `i64_array_bytes_output` input is a sequence of 0 to 128 signed 32-bit integers represented as signed 64-bit ABI values. Empty input is valid, including the ABI representation `(NULL, 0)`; a null pointer with nonzero length is invalid. Values outside signed 32-bit range, arrays longer than 128, and malformed ABI integers also return `-1`.

The output is the retained nondecreasing subsequence encoded as little-endian signed 32-bit values. The return value is the number of output bytes; an empty result returns `0`. Invalid input takes precedence over capacity errors. If the output buffer is null or smaller than the required encoded result, the function returns `-2`.

The maximum output uses 512 bytes. The workload includes source examples, equal and signed values, empty and singleton inputs, signed 32-bit boundaries, malformed lengths and values, and capacity probes. See [`workload.json`](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/stalin_sort.c`](../../../c/s/stalin_sort.c) |
| C3 | [`c3/s/stalin_sort.c3`](../../../c3/s/stalin_sort.c3) |
| C++ | [`cpp/s/stalin_sort.cpp`](../../../cpp/s/stalin_sort.cpp) |
| Elisa | [`elisa/s/stalin_sort.elisa`](../../../elisa/s/stalin_sort.elisa) |
| Nim | [`nim/s/stalin_sort.nim`](../../../nim/s/stalin_sort.nim) |
| Odin | [`odin/s/stalin_sort.odin`](../../../odin/s/stalin_sort.odin) |
| Rust | [`rust/s/stalin_sort.rs`](../../../rust/s/stalin_sort.rs) |
| V | [`v/s/stalin_sort.v`](../../../v/s/stalin_sort.v) |
| Zig | [`zig/s/stalin_sort.zig`](../../../zig/s/stalin_sort.zig) |
