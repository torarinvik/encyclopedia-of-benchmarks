# Sum Of Subsets

This package benchmarks the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/sum_of_subsets.py). Return all source-generated solutions in include-by-index depth-first order. Prune when the path exceeds target or remaining values cannot reach it; return immediately when the current sum equals target. Equal value lists from distinct index selections remain separate. Encode solution count and each length/value record as signed 64-bit little-endian integers.

The `i64_array_bytes_output` ABI uses the packed input layout `[n,target,values[0..n]]`. The workload records the exact input bounds, output encoding, invalid-input result `-1`, insufficient-capacity result `-2`, and bounded output workspace.

Time is O(n·2^n) in the bounded worst case; auxiliary space is O(n + output size).

See [`workload.json`](workload.json) for boundary and invalid-input cases. The independent oracle is [`sum_of_subsets_oracle.py`](../../sum_of_subsets_oracle.py).

## Language ports

- C: [`c/s/sum_of_subsets.c`](../../../c/s/sum_of_subsets.c)
- C3: [`c3/s/sum_of_subsets.c3`](../../../c3/s/sum_of_subsets.c3)
- C++: [`cpp/s/sum_of_subsets.cpp`](../../../cpp/s/sum_of_subsets.cpp)
- Elisa: [`elisa/s/sum_of_subsets.elisa`](../../../elisa/s/sum_of_subsets.elisa)
- Nim: [`nim/s/sum_of_subsets.nim`](../../../nim/s/sum_of_subsets.nim)
- Odin: [`odin/s/sum_of_subsets.odin`](../../../odin/s/sum_of_subsets.odin)
- Rust: [`rust/s/sum_of_subsets.rs`](../../../rust/s/sum_of_subsets.rs)
- V: [`v/s/sum_of_subsets.v`](../../../v/s/sum_of_subsets.v)
- Zig: [`zig/s/sum_of_subsets.zig`](../../../zig/s/sum_of_subsets.zig)
