# Richest customer wealth

The pinned Ruby methods compute each customer's wealth by summing one row, then return the largest row sum. One variant sorts the row sums and takes the last value; the other tracks a maximum starting at zero. On a nonempty rectangular matrix of nonnegative amounts, both return the same scalar. The top-level demonstration prints are outside the benchmark.

## Contract

Input is a signed 64-bit integer array `[rows, columns, row-major account amounts...]`. Rows and columns are each in 1 through 32; every amount is in 0 through 1,000,000; and the packed length must equal `2 + rows * columns`. The return value is the maximum sum of any customer row. The maximum result is 32,000,000, safely within signed 64-bit range. Malformed input or a null input pointer returns `-1`.

The independent [oracle](../../richest_customer_wealth_oracle.py) and [`workload.json`](workload.json) cover the three Ruby examples, ties, zero and single-dimensional matrices, the maximum dimensions and amount, malformed packed matrices, and null input.

## Pinned sources

- [TheAlgorithms/Ruby `data_structures/arrays/richest_customer_wealth.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/richest_customer_wealth.rb)
- [TheAlgorithms/Ruby `data_structures/hash_table/richest_customer_wealth.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/richest_customer_wealth.rb)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/richest_customer_wealth.c`](../../../c/r/richest_customer_wealth.c) |
| C3 | [`c3/r/richest_customer_wealth.c3`](../../../c3/r/richest_customer_wealth.c3) |
| C++ | [`cpp/r/richest_customer_wealth.cpp`](../../../cpp/r/richest_customer_wealth.cpp) |
| Elisa | [`elisa/r/richest_customer_wealth.elisa`](../../../elisa/r/richest_customer_wealth.elisa) |
| Nim | [`nim/r/richest_customer_wealth.nim`](../../../nim/r/richest_customer_wealth.nim) |
| Odin | [`odin/r/richest_customer_wealth.odin`](../../../odin/r/richest_customer_wealth.odin) |
| Rust | [`rust/r/richest_customer_wealth.rs`](../../../rust/r/richest_customer_wealth.rs) |
| V | [`v/r/richest_customer_wealth.v`](../../../v/r/richest_customer_wealth.v) |
| Zig | [`zig/r/richest_customer_wealth.zig`](../../../zig/r/richest_customer_wealth.zig) |
