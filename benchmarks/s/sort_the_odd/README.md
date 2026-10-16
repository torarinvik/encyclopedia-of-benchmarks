# Sort the Odd

This benchmark ports the pinned Elixir `sort_the_odd` function. It sorts only odd values into ascending order and keeps each even value at its original index. Negative odd integers are included in the sorted subsequence.

## Contract

The `i64_array_scalar` input is a raw array of signed 64-bit integers; the ABI length is the item count. Valid arrays contain 0 through 256 values, each in `[-1,000,000, 1,000,000]`. Empty input is valid. Invalid lengths or values return `-1`.

The source returns an array, while this scalar benchmark returns an order-sensitive weighted checksum of that array:

```text
sum((zero_based_index + 1) * (output_value + 1,000,001))
```

The offset keeps each term positive on the bounded input domain. The maximum checksum fits in signed 64-bit arithmetic. Implementations extract the odd values, sort them ascending, then place them back into odd positions while copying even values unchanged. Time is `O(n + m log m)` and auxiliary space is `O(n + m)`, where `m` is the number of odd values.

## Workload and oracle

[`workload.json`](workload.json) covers the published examples, negative odd values, duplicates, even-position preservation, empty input, the maximum length, and invalid values or lengths. The independent scalar oracle is [`benchmarks/sort_the_odd_oracle.py`](../../sort_the_odd_oracle.py).

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/sort_the_odd.c`](../../../c/s/sort_the_odd.c) |
| C3 | [`c3/s/sort_the_odd.c3`](../../../c3/s/sort_the_odd.c3) |
| C++ | [`cpp/s/sort_the_odd.cpp`](../../../cpp/s/sort_the_odd.cpp) |
| Elisa | [`elisa/s/sort_the_odd.elisa`](../../../elisa/s/sort_the_odd.elisa) |
| Nim | [`nim/s/sort_the_odd.nim`](../../../nim/s/sort_the_odd.nim) |
| Odin | [`odin/s/sort_the_odd.odin`](../../../odin/s/sort_the_odd.odin) |
| Rust | [`rust/s/sort_the_odd.rs`](../../../rust/s/sort_the_odd.rs) |
| V | [`v/s/sort_the_odd.v`](../../../v/s/sort_the_odd.v) |
| Zig | [`zig/s/sort_the_odd.zig`](../../../zig/s/sort_the_odd.zig) |

## Reviewed source

- [Elixir `sort_the_odd.ex`](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/codewars/sort_the_odd.ex)
