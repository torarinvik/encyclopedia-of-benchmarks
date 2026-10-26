# Maximum product of three values

Return the largest product obtainable by choosing any three values from the input array. The pinned JavaScript source tracks the three largest and two smallest values in one pass, then compares the product of the three largest with the product of the largest and two smallest.

## Contract

- The `i64_array_scalar` input is `[n, values...]`, with `n` in 3..128 and exactly `n` integer values in `[-1000, 1000]`.
- Return the exact maximum product of any three distinct array positions. Repeated values at different positions may all be selected.
- Malformed packing, an out-of-range value, or `n<3` returns `INT64_MIN`. The source throws when fewer than three values are supplied; the sentinel is the shared finite scalar ABI mapping. `-1` remains a valid output.
- The value bound keeps both candidate products exact in binary64 (as used by JavaScript Number) and within signed 64-bit output range.

## Source and related algorithms

This follows the pinned JavaScript [`MaxProductOfThree.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/MaxProductOfThree.js). It updates the top-three and bottom-two extrema in input order, computes `max1 * max2 * max3` followed by `max1 * min1 * min2`, and returns their maximum. [`maximum_product_subarray`](../maximum_product_subarray/README.md) instead finds a contiguous subarray of arbitrary length; this package always selects exactly three positions, which need not be adjacent.

[`workload.json`](workload.json) covers positive, negative, duplicate, zero, and mixed-sign arrays, plus malformed and source-throwing inputs. All outputs are exact integers under the bounded contract. The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

| Language | Source |
| --- | --- |
| C | [`c/m/max_product_of_three.c`](../../../c/m/max_product_of_three.c) |
| C3 | [`c3/m/max_product_of_three.c3`](../../../c3/m/max_product_of_three.c3) |
| C++ | [`cpp/m/max_product_of_three.cpp`](../../../cpp/m/max_product_of_three.cpp) |
| Elisa | [`elisa/m/max_product_of_three.elisa`](../../../elisa/m/max_product_of_three.elisa) |
| Nim | [`nim/m/max_product_of_three.nim`](../../../nim/m/max_product_of_three.nim) |
| Odin | [`odin/m/max_product_of_three.odin`](../../../odin/m/max_product_of_three.odin) |
| Rust | [`rust/m/max_product_of_three.rs`](../../../rust/m/max_product_of_three.rs) |
| V | [`v/m/max_product_of_three.v`](../../../v/m/max_product_of_three.v) |
| Zig | [`zig/m/max_product_of_three.zig`](../../../zig/m/max_product_of_three.zig) |
