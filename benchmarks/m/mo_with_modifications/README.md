# Mo's algorithm with modifications

Input is `[N,Q,initial_values...,(operation,first,second)*Q]`, with `1<=N<=64`, `Q<=64`, and values in `0..15`. Operation 0 assigns a new value to one position. Operation 1 asks for the number of distinct values in an inclusive range. The result adds `query_index*(distinct_count+1)` for each query in original order. Malformed input returns `-1`.

The primary records each point update's old and new value, attaches the update count to every query, and sorts queries in three-dimensional Mo order. As the range endpoints and time move, it adds/removes values from a frequency table and applies or rolls back updates. The independent oracle executes updates in input order and scans each queried slice directly. The workload uses small bounds to exercise offline reordering and rollback while keeping reference work bounded.

This extends static Mo ordering with an explicit time coordinate for point assignments; it is distinct from [`mos_algorithm`](../mos_algorithm/README.md), whose array does not change. The method is described by [OI Wiki's modifiable Mo article](https://oi-wiki.org/misc/modifiable-mo-algo/). Only the algorithm description was used; code, prose, and examples are independently authored.

| Language | Port |
|---|---|
| C | [c/m/mo_with_modifications.c](../../../c/m/mo_with_modifications.c) |
| C3 | [c3/m/mo_with_modifications.c3](../../../c3/m/mo_with_modifications.c3) |
| C++ | [cpp/m/mo_with_modifications.cpp](../../../cpp/m/mo_with_modifications.cpp) |
| Elisa | [elisa/m/mo_with_modifications.elisa](../../../elisa/m/mo_with_modifications.elisa) |
| Mojo | [mojo/m/mo_with_modifications.mojo](../../../mojo/m/mo_with_modifications.mojo) |
| Nim | [nim/m/mo_with_modifications.nim](../../../nim/m/mo_with_modifications.nim) |
| Odin | [odin/m/mo_with_modifications.odin](../../../odin/m/mo_with_modifications.odin) |
| Rust | [rust/m/mo_with_modifications.rs](../../../rust/m/mo_with_modifications.rs) |
| V | [v/m/mo_with_modifications.v](../../../v/m/mo_with_modifications.v) |
| Zig | [zig/m/mo_with_modifications.zig](../../../zig/m/mo_with_modifications.zig) |
