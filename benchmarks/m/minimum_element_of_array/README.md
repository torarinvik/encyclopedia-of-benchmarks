# Minimum element of an array

The pinned Python source is randomized quickselect, not a full sort: it chooses a random pivot, partitions with `<=`, and recurses into the side containing the requested one-based order statistic. This benchmark makes the pivot stream reproducible by supplying a 32-bit seed and using xorshift32; seed zero maps to `0x9e3779b9`.

## Contract

Input is `[n, k, seed, values...]` in the `i64_array_scalar` ABI. `n` is 1 through 128, `k` is in `[1,n]`, the seed is in `[0,2,147,483,647]`, and values are distinct signed integers in `[-1,000,000,1,000,000]`. Output is the `k`th smallest value. Invalid input returns `-1`.

Distinct values match the source documentation’s expected-linear-time assumption. The seed makes the source’s randomized pivot behavior repeatable across the nine implementations.

Pinned source: [TheAlgorithms/Python `minimum_element_of_array.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/minimum_element_of_array.py). [`workload.json`](workload.json) covers first, middle, and last ranks, one-element input, and invalid domains.

| Language | Port |
|---|---|
| C | [`c/m/minimum_element_of_array.c`](../../../c/m/minimum_element_of_array.c) |
| C3 | [`c3/m/minimum_element_of_array.c3`](../../../c3/m/minimum_element_of_array.c3) |
| C++ | [`cpp/m/minimum_element_of_array.cpp`](../../../cpp/m/minimum_element_of_array.cpp) |
| Elisa | [`elisa/m/minimum_element_of_array.elisa`](../../../elisa/m/minimum_element_of_array.elisa) |
| Nim | [`nim/m/minimum_element_of_array.nim`](../../../nim/m/minimum_element_of_array.nim) |
| Odin | [`odin/m/minimum_element_of_array.odin`](../../../odin/m/minimum_element_of_array.odin) |
| Rust | [`rust/m/minimum_element_of_array.rs`](../../../rust/m/minimum_element_of_array.rs) |
| V | [`v/m/minimum_element_of_array.v`](../../../v/m/minimum_element_of_array.v) |
| Zig | [`zig/m/minimum_element_of_array.zig`](../../../zig/m/minimum_element_of_array.zig) |
