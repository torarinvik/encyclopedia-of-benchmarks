# Print multiplication table

This benchmark follows the pinned Python `multiplication_table` routine. It returns one line for each multiplier from 1 through `number_of_terms`, formatted as `number * multiplier = product`; lines are joined with `\n` and there is no trailing newline. A nonpositive term count produces the empty string.

## Contract

- Input is `[number, number_of_terms]`; `number` is from -1,000,000 through 1,000,000, and `number_of_terms` is from -20 through 20.
- Positive term counts emit the exact ASCII table. Zero or negative term counts emit an empty byte string.
- The return value is the output byte length. Values outside either input bound return `-1`; insufficient output capacity returns `-2`.
- The workload uses `i64_array_bytes_output_call`; output bytes preserve the source's spaces, `*`, `=`, and line separators exactly.

The Python source function is named `multiplication_table` and returns a string; the benchmark captures that string as ASCII bytes. The example for `(3, 5)` is five lines ending in `3 * 5 = 15`, with no final newline.

[`workload.json`](workload.json) covers zero and negative term counts, positive and negative multiplicands, the pinned example, a zero multiplicand, input bounds, and invalid inputs.

| Language | Source |
| --- | --- |
| C | [`c/p/print_multiplication_table.c`](../../../c/p/print_multiplication_table.c) |
| C3 | [`c3/p/print_multiplication_table.c3`](../../../c3/p/print_multiplication_table.c3) |
| C++ | [`cpp/p/print_multiplication_table.cpp`](../../../cpp/p/print_multiplication_table.cpp) |
| Elisa | [`elisa/p/print_multiplication_table.elisa`](../../../elisa/p/print_multiplication_table.elisa) |
| Nim | [`nim/p/print_multiplication_table.nim`](../../../nim/p/print_multiplication_table.nim) |
| Odin | [`odin/p/print_multiplication_table.odin`](../../../odin/p/print_multiplication_table.odin) |
| Rust | [`rust/p/print_multiplication_table.rs`](../../../rust/p/print_multiplication_table.rs) |
| V | [`v/p/print_multiplication_table.v`](../../../v/p/print_multiplication_table.v) |
| Zig | [`zig/p/print_multiplication_table.zig`](../../../zig/p/print_multiplication_table.zig) |

Pinned source: [TheAlgorithms/Python `print_multiplication_table.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/print_multiplication_table.py).
