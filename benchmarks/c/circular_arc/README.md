# Circular arc length and sector area

This package ports both functions in the pinned [TheAlgorithms/JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/CircularArc.js). It uses the accompanying `degreeToRadian` operation `degrees * (pi / 180)`. Mode 0 returns arc length (`radius * angle`); mode 1 returns the sector area (`radius² * angle / 2`).

The `i64_array_float64` ABI packs `[mode, radius, degrees]`. Radius is bounded to -1,000,000..1,000,000 and degrees to -360,000..360,000. Mode must be 0 or 1. Invalid shape or values return `-1e300`. The bound keeps integer intermediate products within signed 64-bit range while covering negative angles and multiple turns.

[`workload.json`](workload.json) covers both functions, signs, zero values, full turns, bounds, and invalid inputs.

The source-backed expected-value check is in [`benchmarks/run_i64_array_float64.py`](../../run_i64_array_float64.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/circular_arc.c`](../../../c/c/circular_arc.c) |
| C3 | [`c3/c/circular_arc.c3`](../../../c3/c/circular_arc.c3) |
| C++ | [`cpp/c/circular_arc.cpp`](../../../cpp/c/circular_arc.cpp) |
| Elisa | [`elisa/c/circular_arc.elisa`](../../../elisa/c/circular_arc.elisa) |
| Nim | [`nim/c/circular_arc.nim`](../../../nim/c/circular_arc.nim) |
| Odin | [`odin/c/circular_arc.odin`](../../../odin/c/circular_arc.odin) |
| Rust | [`rust/c/circular_arc.rs`](../../../rust/c/circular_arc.rs) |
| V | [`v/c/circular_arc.v`](../../../v/c/circular_arc.v) |
| Zig | [`zig/c/circular_arc.zig`](../../../zig/c/circular_arc.zig) |
