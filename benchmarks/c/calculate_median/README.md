# Calculate median

Select the median from an already sorted array. The pinned TypeScript source indexes the middle position directly and averages the central pair for even lengths. This package preserves that sorted-input algorithm and reports twice the median so half-integer results fit exactly in the shared integer scalar ABI.

## Contract

- The valid input domain is a nonempty array of 1 through 1,024 signed 32-bit integers, already sorted in nondecreasing order.
- Odd lengths return twice the middle value. Even lengths return the sum of the two middle values. This is exactly twice the statistical median.
- Empty input and lengths above 1,024 return `INT64_MIN`. Sortedness and the signed 32-bit value range are caller preconditions, so the measured function can keep direct selection constant-time.
- The source accepts floating-point numbers and throws on empty input. This benchmark narrows the values to signed integers and uses a sentinel for malformed inputs; the factor-of-two output encoding preserves all source results exactly on the benchmark domain.

## Source and workload

The pinned [TypeScript `calculate_median.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/calculate_median.ts) documents an already sorted array, returns its middle item or the average of the central pair, and rejects an empty array. [`workload.json`](workload.json) covers odd and even lengths, negative half-integer results, duplicates, integer boundaries, and malformed inputs.

Build with the `i64_array_scalar` ABI family. `benchmarks/run_i64_array_scalar.py` records measurements. Verify all nine ports against the direct-indexing oracle and check recorder output with:

```sh
python3 benchmarks/verify_calculate_median.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/calculate_median.c`](../../../c/c/calculate_median.c) |
| C3 | [`c3/c/calculate_median.c3`](../../../c3/c/calculate_median.c3) |
| C++ | [`cpp/c/calculate_median.cpp`](../../../cpp/c/calculate_median.cpp) |
| Elisa | [`elisa/c/calculate_median.elisa`](../../../elisa/c/calculate_median.elisa) |
| Nim | [`nim/c/calculate_median.nim`](../../../nim/c/calculate_median.nim) |
| Odin | [`odin/c/calculate_median.odin`](../../../odin/c/calculate_median.odin) |
| Rust | [`rust/c/calculate_median.rs`](../../../rust/c/calculate_median.rs) |
| V | [`v/c/calculate_median.v`](../../../v/c/calculate_median.v) |
| Zig | [`zig/c/calculate_median.zig`](../../../zig/c/calculate_median.zig) |
