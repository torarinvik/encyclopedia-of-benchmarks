# Log two

This benchmark ports the pinned JavaScript `logTwo`, which counts repeated signed 32-bit right shifts until the value becomes zero. For positive values in the bounded domain, the result is floor(log2(n)); zero returns zero in the source.

## Contract

Input is a single integer in `[0, 2^31-1]`. The upper bound ensures JavaScript's signed 32-bit shifts match ordinary positive integer shifts in every port. Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../log_two_oracle.py), and the pinned [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/LogTwo.js).

| Language | Port |
|---|---|
| C | [`c/l/log_two.c`](../../../c/l/log_two.c) |
| C3 | [`c3/l/log_two.c3`](../../../c3/l/log_two.c3) |
| C++ | [`cpp/l/log_two.cpp`](../../../cpp/l/log_two.cpp) |
| Elisa | [`elisa/l/log_two.elisa`](../../../elisa/l/log_two.elisa) |
| Nim | [`nim/l/log_two.nim`](../../../nim/l/log_two.nim) |
| Odin | [`odin/l/log_two.odin`](../../../odin/l/log_two.odin) |
| Rust | [`rust/l/log_two.rs`](../../../rust/l/log_two.rs) |
| V | [`v/l/log_two.v`](../../../v/l/log_two.v) |
| Zig | [`zig/l/log_two.zig`](../../../zig/l/log_two.zig) |
