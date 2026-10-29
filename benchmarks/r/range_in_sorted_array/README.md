# Range in Sorted Array

This benchmark ports the Java `sortedRange` method, which returns the first and last indices of a key in a sorted array.

## Contract

- The `i64_array_bytes_output` ABI input is `[n, values[0], ..., values[n-1], key]` with exactly `n + 2` signed 64-bit slots.
- `n` is in `0..512`; each value and key must fit signed 32-bit range. Values must be nondecreasing, as required by the source search.
- The output buffer contains two little-endian signed 32-bit indices: first occurrence, then last occurrence. A missing key and an empty array produce `[-1,-1]`. Successful calls return `8` bytes; malformed inputs return `-1`; insufficient output capacity returns `-2`.
- The ports preserve the source's two iterative binary searches and its left/right neighbor checks. The small array bound keeps Java-style indices and midpoint arithmetic in range.

This is a paired occurrence-range search, distinct from `lower_bound` and `upper_bound`, which each return one boundary, and `sparse_table`, which answers static array minimum queries. The Java source also exposes a count-less-than helper; this package benchmarks its primary `sortedRange` operation.

## Pinned source

- Java [`RangeInSortedArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/RangeInSortedArray.java)

## Workload and build

[`workload.json`](workload.json) covers empty and singleton arrays, duplicates, absent keys, invalid ordering, and malformed values. It uses the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm range_in_sorted_array --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/r/range_in_sorted_array/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm range_in_sorted_array
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/range_in_sorted_array.c`](../../../c/r/range_in_sorted_array.c) |
| C3 | [`c3/r/range_in_sorted_array.c3`](../../../c3/r/range_in_sorted_array.c3) |
| C++ | [`cpp/r/range_in_sorted_array.cpp`](../../../cpp/r/range_in_sorted_array.cpp) |
| Elisa | [`elisa/r/range_in_sorted_array.elisa`](../../../elisa/r/range_in_sorted_array.elisa) |
| Nim | [`nim/r/range_in_sorted_array.nim`](../../../nim/r/range_in_sorted_array.nim) |
| Odin | [`odin/r/range_in_sorted_array.odin`](../../../odin/r/range_in_sorted_array.odin) |
| Rust | [`rust/r/range_in_sorted_array.rs`](../../../rust/r/range_in_sorted_array.rs) |
| V | [`v/r/range_in_sorted_array.v`](../../../v/r/range_in_sorted_array.v) |
| Zig | [`zig/r/range_in_sorted_array.zig`](../../../zig/r/range_in_sorted_array.zig) |
