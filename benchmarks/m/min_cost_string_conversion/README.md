# Minimum Cost String Conversion

This package benchmarks the table computation from the pinned [TheAlgorithms/F-Sharp implementation](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/MinCostStringConversion.fs), cross-checked against the pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/min_cost_string_conversion.py). It fills the complete edit-cost and operation tables, preserving the source's strict comparison order: start from copy/replace diagonal, then use deletion only when strictly cheaper, then insertion only when strictly cheaper.

The packed input is `[src_len,src_ASCII...,dst_len,dst_ASCII...,copy_cost,replace_cost,delete_cost,insert_cost]`. Text lengths are 0..32, bytes are ASCII 0..127, and signed costs are -1000..1000. Output is a little-endian i64 cost table (`rows,cols`, then row-major costs), followed by a little-endian i64 operation table (`rows,cols`, then row-major `(op_code,char_a,char_b)` triples). Codes are 0 initial, 1 copy, 2 replace, 3 delete, and 4 insert. Initial cells use `(0,0,0)`; copy uses `(source_char,0)`; replace uses `(source_char,destination_char)`; delete uses `(source_char,0)`; insert uses `(0,destination_char)`.

The maximum output is 34,880 bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`. Runtime and space are both O(src_len × dst_len).

See [`workload.json`](workload.json) for fixtures and [`min_cost_string_conversion_oracle.py`](../../min_cost_string_conversion_oracle.py) for the independent oracle.

## Language ports

- C: [`c/m/min_cost_string_conversion.c`](../../../c/m/min_cost_string_conversion.c)
- C3: [`c3/m/min_cost_string_conversion.c3`](../../../c3/m/min_cost_string_conversion.c3)
- C++: [`cpp/m/min_cost_string_conversion.cpp`](../../../cpp/m/min_cost_string_conversion.cpp)
- Elisa: [`elisa/m/min_cost_string_conversion.elisa`](../../../elisa/m/min_cost_string_conversion.elisa)
- Nim: [`nim/m/min_cost_string_conversion.nim`](../../../nim/m/min_cost_string_conversion.nim)
- Odin: [`odin/m/min_cost_string_conversion.odin`](../../../odin/m/min_cost_string_conversion.odin)
- Rust: [`rust/m/min_cost_string_conversion.rs`](../../../rust/m/min_cost_string_conversion.rs)
- V: [`v/m/min_cost_string_conversion.v`](../../../v/m/min_cost_string_conversion.v)
- Zig: [`zig/m/min_cost_string_conversion.zig`](../../../zig/m/min_cost_string_conversion.zig)
