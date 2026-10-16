# Subarray sum equals k

Count contiguous subarrays whose values sum to a requested target. The package follows the prefix-sum frequency method used by the pinned Java and Rust implementations.

## Contract

The `i64_array_scalar` input is `[count, target, values...]`, with exactly `count` values after the first two fields. `count` is in `0..512`; `target` and each value must fit signed 32-bit integers. The result is the number of contiguous subarrays with sum equal to `target`. Invalid lengths, counts, or values return `I64_MIN`.

Negative values and an empty value array are valid. The bounded maximum count of subarrays is `512 × 513 / 2`, which fits the source functions' signed 32-bit count type. The ports use a bounded open-addressed table to store prefix-sum frequencies.

## Sources

- Java [`SubarraySumEqualsK.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/prefixsum/SubarraySumEqualsK.java)
- Rust [`subarray_sum_equals_k.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/subarray_sum_equals_k.rs)

## Workload and recording

[`workload.json`](workload.json) covers both pinned examples, repeated and negative prefix sums, empty and zero-heavy arrays, signed 32-bit boundaries, malformed lengths, and out-of-range values. Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm subarray_sum_equals_k --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/subarray_sum_equals_k/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/s/subarray_sum_equals_k.c`](../../../c/s/subarray_sum_equals_k.c) |
| C3 | [`c3/s/subarray_sum_equals_k.c3`](../../../c3/s/subarray_sum_equals_k.c3) |
| C++ | [`cpp/s/subarray_sum_equals_k.cpp`](../../../cpp/s/subarray_sum_equals_k.cpp) |
| Elisa | [`elisa/s/subarray_sum_equals_k.elisa`](../../../elisa/s/subarray_sum_equals_k.elisa) |
| Nim | [`nim/s/subarray_sum_equals_k.nim`](../../../nim/s/subarray_sum_equals_k.nim) |
| Odin | [`odin/s/subarray_sum_equals_k.odin`](../../../odin/s/subarray_sum_equals_k.odin) |
| Rust | [`rust/s/subarray_sum_equals_k.rs`](../../../rust/s/subarray_sum_equals_k.rs) |
| V | [`v/s/subarray_sum_equals_k.v`](../../../v/s/subarray_sum_equals_k.v) |
| Zig | [`zig/s/subarray_sum_equals_k.zig`](../../../zig/s/subarray_sum_equals_k.zig) |
