# Products of All Other Elements

For each input position, return the product of every other array value. This package follows the final, O(1)-extra-space `products(nums)` definition in the pinned Ruby source.

## Contract

- Input is a packed signed 64-bit array `[n, values...]`. Require `0 <= n <= 32`, exactly `n + 1` input values, and each element in `[-2, 2]`. The parser admits up to 34 values so an extra packed element can be rejected by the implementation.
- For `n < 2`, return the empty result, matching the source method.
- For `n >= 2`, initialize the result prefix with 1, append successive prefix products, then scan right-to-left. At each index, multiply the preceding prefix result by the suffix product and current input value; update the suffix product afterward.
- Encode each result as one signed 64-bit little-endian word. Return the number of output bytes (`8*n`); return 0 when `n < 2`. Invalid input returns -1. Insufficient output capacity returns -2 and writes no bytes.
- The input bounds keep all source intermediate products and outputs within signed 64-bit range. The workspace is 256 bytes; runtime is O(n), with the result vector as the only O(n) storage.

## Source semantics and related algorithms

This follows [TheAlgorithms/Ruby `get_products_of_all_other_elements.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/get_products_of_all_other_elements.rb) at commit `bda11bdfd83b7958e1ca98247e5e43100ca88865`. The file defines three approaches under the name `products`; Ruby uses the final definition, which returns `[]` for fewer than two values and otherwise performs the prefix pass and right-to-left suffix update. The ports preserve that final method's traversal and update order.

This benchmark returns one product per original index. It is distinct from [`max_product_subarray`](../../m/max_product_subarray/README.md), which returns the maximum product of a contiguous subarray. The independent byte-output oracle is [`get_products_of_all_other_elements_oracle.py`](../../get_products_of_all_other_elements_oracle.py).

## Workload

[`workload.json`](workload.json) covers empty and singleton input, two values, positive and negative products, one and multiple zeros, the 32-element boundary, malformed packing and values, and insufficient output capacity.

Build and verify with the `i64_array_bytes_output` family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm get_products_of_all_other_elements --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm get_products_of_all_other_elements
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/get_products_of_all_other_elements.c`](../../../c/g/get_products_of_all_other_elements.c) |
| C3 | [`c3/g/get_products_of_all_other_elements.c3`](../../../c3/g/get_products_of_all_other_elements.c3) |
| C++ | [`cpp/g/get_products_of_all_other_elements.cpp`](../../../cpp/g/get_products_of_all_other_elements.cpp) |
| Elisa | [`elisa/g/get_products_of_all_other_elements.elisa`](../../../elisa/g/get_products_of_all_other_elements.elisa) |
| Nim | [`nim/g/get_products_of_all_other_elements.nim`](../../../nim/g/get_products_of_all_other_elements.nim) |
| Odin | [`odin/g/get_products_of_all_other_elements.odin`](../../../odin/g/get_products_of_all_other_elements.odin) |
| Rust | [`rust/g/get_products_of_all_other_elements.rs`](../../../rust/g/get_products_of_all_other_elements.rs) |
| V | [`v/g/get_products_of_all_other_elements.v`](../../../v/g/get_products_of_all_other_elements.v) |
| Zig | [`zig/g/get_products_of_all_other_elements.zig`](../../../zig/g/get_products_of_all_other_elements.zig) |
