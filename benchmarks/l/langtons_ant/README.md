# Langton's ant

This benchmark ports the pinned Python ant state transition without its plotting layer. On a white square the ant turns clockwise; on a black square it turns counterclockwise. It then moves one cell and flips the square it left.

## Contract

Input is `[steps]` for a fixed 5×5 all-white board, starting at `(2,2)` and facing left. Steps are limited to 0 through 6 so the pinned implementation stays inside its finite board. The scalar packs the final black-cell mask (25 bits), ant position index `x*5+y` (5 bits), and direction (2 bits). Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../langtons_ant_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/langtons_ant.py).

| Language | Port |
|---|---|
| C | [`c/l/langtons_ant.c`](../../../c/l/langtons_ant.c) |
| C3 | [`c3/l/langtons_ant.c3`](../../../c3/l/langtons_ant.c3) |
| C++ | [`cpp/l/langtons_ant.cpp`](../../../cpp/l/langtons_ant.cpp) |
| Elisa | [`elisa/l/langtons_ant.elisa`](../../../elisa/l/langtons_ant.elisa) |
| Nim | [`nim/l/langtons_ant.nim`](../../../nim/l/langtons_ant.nim) |
| Odin | [`odin/l/langtons_ant.odin`](../../../odin/l/langtons_ant.odin) |
| Rust | [`rust/l/langtons_ant.rs`](../../../rust/l/langtons_ant.rs) |
| V | [`v/l/langtons_ant.v`](../../../v/l/langtons_ant.v) |
| Zig | [`zig/l/langtons_ant.zig`](../../../zig/l/langtons_ant.zig) |
