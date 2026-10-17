# Spread sort for Java Integer arrays

This package ports the pinned Java `SpreadSort.sort` for nonnull `Integer[]` inputs. The adapter accepts a direct signed-i64 array of 0 through 128 values, each in signed-i32 range; there is no count prefix. The adapter returns the ascending values as little-endian signed 32-bit integers, preserving duplicates, and returns the output byte count (4*n). For length zero, the ABI still supplies a nonnull input frame; the algorithm reads no values, succeeds with 0 output bytes, and needs no output buffer. Invalid input returns `-1`; null or short output for a nonempty valid input returns `-2` without writing.

The Java default settings are insertion threshold 16, initial bucket capacity 16, and minimum bucket count 2. Segments of length at most 16 use insertion sort; a length-17 segment enters bucket distribution. Equal-valued large segments return immediately. Insertion sort shifts only strictly greater values, and bucket collection keeps bucket order. The bounded ports preserve the threshold and bucket behavior, using fixed backing storage sized for the maximum input instead of reproducing Java's bucket-array growth.

For Java `Integer`, `compareTo` returns only -1, 0, or 1. The source uses those comparison results as numeric distances when computing its bucket index. On a nonconstant segment, the minimum maps to bucket 0 and every strictly larger value maps to bucket `floor(bucket_count/2)`; recursion sorts those two populated buckets. This unusual distribution remains correct for ascending integer order and is preserved by the ports. The maximum length of 128 bounds the recursive depth.

The independent oracle uses Python's built-in sort and encodes the result separately from the ports.

## Pinned source

- [Java SpreadSort.java at e43ec3897e48f23843972d02cd05a5bb1b6864a2](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SpreadSort.java)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm spread_sort --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm spread_sort
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/spread_sort.c`](../../../c/s/spread_sort.c) |
| C3 | [`c3/s/spread_sort.c3`](../../../c3/s/spread_sort.c3) |
| C++ | [`cpp/s/spread_sort.cpp`](../../../cpp/s/spread_sort.cpp) |
| Elisa | [`elisa/s/spread_sort.elisa`](../../../elisa/s/spread_sort.elisa) |
| Nim | [`nim/s/spread_sort.nim`](../../../nim/s/spread_sort.nim) |
| Odin | [`odin/s/spread_sort.odin`](../../../odin/s/spread_sort.odin) |
| Rust | [`rust/s/spread_sort.rs`](../../../rust/s/spread_sort.rs) |
| V | [`v/s/spread_sort.v`](../../../v/s/spread_sort.v) |
| Zig | [`zig/s/spread_sort.zig`](../../../zig/s/spread_sort.zig) |
