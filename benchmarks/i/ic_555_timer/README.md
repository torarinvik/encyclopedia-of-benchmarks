# Astable 555 timer

This package ports both pinned Python functions for an astable 555 timer: frequency and duty cycle.

## Contract

Input is `[mode, R1, R2, C]`, where mode `0` selects frequency in hertz, and mode `1` selects duty cycle in percent. `R1` and `R2` are positive integral ohm values up to 1,000,000. For frequency, `C` is a positive integral microfarad value up to 1,000,000. For duty cycle, `C` is ignored and is set to zero in the packed input. Frequency follows `(1.44 / ((R1 + 2*R2) * C)) * 10^6`; duty cycle follows `((R1 + R2) / (R1 + 2*R2)) * 100`. Invalid inputs return `-1e300`.

See [`workload.json`](workload.json) and the independent [oracle](../../ic_555_timer_oracle.py). The benchmark preserves the order of operations in the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/ic_555_timer.py).

| Language | Port |
|---|---|
| C | [`c/i/ic_555_timer.c`](../../../c/i/ic_555_timer.c) |
| C3 | [`c3/i/ic_555_timer.c3`](../../../c3/i/ic_555_timer.c3) |
| C++ | [`cpp/i/ic_555_timer.cpp`](../../../cpp/i/ic_555_timer.cpp) |
| Elisa | [`elisa/i/ic_555_timer.elisa`](../../../elisa/i/ic_555_timer.elisa) |
| Nim | [`nim/i/ic_555_timer.nim`](../../../nim/i/ic_555_timer.nim) |
| Odin | [`odin/i/ic_555_timer.odin`](../../../odin/i/ic_555_timer.odin) |
| Rust | [`rust/i/ic_555_timer.rs`](../../../rust/i/ic_555_timer.rs) |
| V | [`v/i/ic_555_timer.v`](../../../v/i/ic_555_timer.v) |
| Zig | [`zig/i/ic_555_timer.zig`](../../../zig/i/ic_555_timer.zig) |
