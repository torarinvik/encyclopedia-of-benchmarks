# Product sum

The pinned Python source recursively sums integer leaves in a nested special array, multiplying each list's subtotal by its depth. The root list starts at depth 1. The source also includes an iterative implementation; this benchmark targets the recursive `product_sum_array` behavior.

## Contract

The signed-i64 input is `[token_count, tokens...]`. The root list is implicit. `2001` begins a child list and `2002` closes it; all other tokens are integer leaves in `[-1000, 1000]`. There are at most 128 tokens and nested depth is at most 16. Child-list markers must be balanced, and no end marker may close the implicit root. Output is the sum of every leaf times its containing list depth. Malformed inputs return `-1`. The bounds keep the result well within signed 64-bit range.

See [`workload.json`](workload.json) and the runtime [oracle](../../product_sum_oracle.py). Pinned source: [TheAlgorithms/Python `product_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/product_sum.py).

| Language | Port |
|---|---|
| C | [`c/p/product_sum.c`](../../../c/p/product_sum.c) |
| C3 | [`c3/p/product_sum.c3`](../../../c3/p/product_sum.c3) |
| C++ | [`cpp/p/product_sum.cpp`](../../../cpp/p/product_sum.cpp) |
| Elisa | [`elisa/p/product_sum.elisa`](../../../elisa/p/product_sum.elisa) |
| Nim | [`nim/p/product_sum.nim`](../../../nim/p/product_sum.nim) |
| Odin | [`odin/p/product_sum.odin`](../../../odin/p/product_sum.odin) |
| Rust | [`rust/p/product_sum.rs`](../../../rust/p/product_sum.rs) |
| V | [`v/p/product_sum.v`](../../../v/p/product_sum.v) |
| Zig | [`zig/p/product_sum.zig`](../../../zig/p/product_sum.zig) |
