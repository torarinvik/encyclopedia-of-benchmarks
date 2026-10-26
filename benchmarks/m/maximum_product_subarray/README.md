# Maximum product subarray

Return the greatest product of a nonempty contiguous segment of an integer array. The implementations track the greatest and least products ending at each position because multiplying by a negative value can exchange their roles.

## Contract

- Input is an array of signed 64-bit values with length 1 through 9.
- Each value is in `[-10, 10]`. Every contiguous product therefore fits in a signed 32-bit integer, including the Java source's final cast.
- Return the maximum product of any nonempty contiguous segment.
- Null, empty, overlength, or out-of-range inputs return `INT64_MIN`, outside the valid result range.

The pinned Java source returns zero for null or empty arrays; the Ruby source assumes a nonempty input. The benchmark's invalid-input sentinel is the common adapter policy. The valid nonempty domain preserves both sources' recurrence and result.
The pinned Python `max_product_subarray` source uses the same maximum/minimum ending-product recurrence and aliases this package; its empty-input result is outside the shared nonempty domain.

## Workload and oracle

[`workload.json`](workload.json) covers singleton inputs, zeros, sign changes, the source examples, the nine-element product boundary, and malformed inputs. The independent brute-force oracle is [`maximum_product_subarray_oracle.py`](../../maximum_product_subarray_oracle.py).

## Reviewed source implementations

- [TheAlgorithms/Java `MaximumProductSubarray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/MaximumProductSubarray.java)
- [TheAlgorithms/Ruby `maximum_product_subarray.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/maximum_product_subarray.rb)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm maximum_product_subarray --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm maximum_product_subarray
python3 benchmarks/verify_i64_array_scalar.py --algorithm maximum_product_subarray
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/maximum_product_subarray.c`](../../../c/m/maximum_product_subarray.c) |
| C3 | [`c3/m/maximum_product_subarray.c3`](../../../c3/m/maximum_product_subarray.c3) |
| C++ | [`cpp/m/maximum_product_subarray.cpp`](../../../cpp/m/maximum_product_subarray.cpp) |
| Elisa | [`elisa/m/maximum_product_subarray.elisa`](../../../elisa/m/maximum_product_subarray.elisa) |
| Nim | [`nim/m/maximum_product_subarray.nim`](../../../nim/m/maximum_product_subarray.nim) |
| Odin | [`odin/m/maximum_product_subarray.odin`](../../../odin/m/maximum_product_subarray.odin) |
| Rust | [`rust/m/maximum_product_subarray.rs`](../../../rust/m/maximum_product_subarray.rs) |
| V | [`v/m/maximum_product_subarray.v`](../../../v/m/maximum_product_subarray.v) |
| Zig | [`zig/m/maximum_product_subarray.zig`](../../../zig/m/maximum_product_subarray.zig) |
