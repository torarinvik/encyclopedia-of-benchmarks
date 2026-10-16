# Count Less Than or Equal in a Sorted Array

This benchmark ports `getCountLessThan` and its `getLessThan` helper from the pinned Java `RangeInSortedArray.java` source.

## Contract

- The `i64_array_scalar` input is packed as `[key, values[0], ..., values[n-1]]`. The key and each value must fit signed 32-bit range. There may be 0 to 512 values, in nondecreasing order; duplicates are allowed.
- The result is the count of values less than or equal to the key, which is the index immediately after the last qualifying value. An empty array returns 0. If all values qualify, the result is `n`.
- A missing key, more than 512 values, an out-of-range key or value, or a descending adjacent pair returns -1. The packed input length is bounded to 514 slots so the workload can include one over-bound case.
- The ports preserve the source's inclusive-bound binary search and update the result to `middle + 1` when `values[middle] <= key`.

The Java method's Javadoc says “strictly less,” but the implementation calls `getLessThan`, whose helper tests `nums[mid] > key` and therefore counts values equal to the key too. This result differs from the local Java-canonical `upper_bound` at and above the maximum: that routine clamps its final insertion position to `n - 1`, while this helper returns `n`.

## Pinned source

- Java [`RangeInSortedArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/RangeInSortedArray.java)

## Workload and build

[`workload.json`](workload.json) covers empty and singleton arrays, duplicate runs, hits and misses, signed 32-bit boundaries, descending data, and malformed lengths and values. The independent expected-result function is [`count_less_equal_in_sorted_array_oracle.py`](../../count_less_equal_in_sorted_array_oracle.py). The nine ports use the shared `i64_array_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm count_less_equal_in_sorted_array --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/count_less_equal_in_sorted_array/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms count_less_equal_in_sorted_array
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/count_less_equal_in_sorted_array.c`](../../../c/c/count_less_equal_in_sorted_array.c) |
| C3 | [`c3/count_less_equal_in_sorted_array.c3`](../../../c3/c/count_less_equal_in_sorted_array.c3) |
| C++ | [`cpp/count_less_equal_in_sorted_array.cpp`](../../../cpp/c/count_less_equal_in_sorted_array.cpp) |
| Elisa | [`elisa/count_less_equal_in_sorted_array.elisa`](../../../elisa/c/count_less_equal_in_sorted_array.elisa) |
| Nim | [`nim/count_less_equal_in_sorted_array.nim`](../../../nim/c/count_less_equal_in_sorted_array.nim) |
| Odin | [`odin/count_less_equal_in_sorted_array.odin`](../../../odin/c/count_less_equal_in_sorted_array.odin) |
| Rust | [`rust/count_less_equal_in_sorted_array.rs`](../../../rust/c/count_less_equal_in_sorted_array.rs) |
| V | [`v/count_less_equal_in_sorted_array.v`](../../../v/c/count_less_equal_in_sorted_array.v) |
| Zig | [`zig/count_less_equal_in_sorted_array.zig`](../../../zig/c/count_less_equal_in_sorted_array.zig) |
