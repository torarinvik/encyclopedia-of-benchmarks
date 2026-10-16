# Vector2

This package ports the public operations of the pinned JavaScript [`Vector2`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Vectors/Vector2.js) class. The benchmark uses finite binary64 coordinates and a fixed operation selector so each call has a bounded, deterministic result.

The input is `[op, ax, ay, bx, by, scalar]`, with `op` an exact integer from `0` through `10`; coordinates are in `[-1000, 1000]`. Operations are: `0` exact equality, `1` approximate equality, `2` length, `3` normalize, `4` add, `5` subtract, `6` scalar multiply, `7` distance, `8` dot product, `9` rotate in radians, and `10` angle between. Approximate equality uses strict componentwise `< epsilon`, with epsilon in `[0, 2000]`. Scalar multiplication uses a factor in `[-1000, 1000]`; rotation uses an angle in `[-2π, 2π]`. Unused arguments must be zero to make each operation's encoding unambiguous.

Equality operations and scalar-valued methods return one float64; vector-valued methods return two components. Normalizing a vector whose computed source length is zero is invalid, matching the source exception. Invalid inputs return `-1` without writing output; a null or undersized output buffer returns `-2`. Comparisons use absolute and relative tolerances of `1e-12` for floating outputs.

The source's public fields may be externally mutated, but its methods return values without mutating either vector. JavaScript coercion behavior for nonnumeric inputs is outside this numeric ABI. The independent oracle and workload are in [`vector2_oracle.py`](../../vector2_oracle.py) and [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | [`c/v/vector2.c`](../../../c/v/vector2.c) |
| C3 | [`c3/v/vector2.c3`](../../../c3/v/vector2.c3) |
| C++ | [`cpp/v/vector2.cpp`](../../../cpp/v/vector2.cpp) |
| Elisa | [`elisa/v/vector2.elisa`](../../../elisa/v/vector2.elisa) |
| Nim | [`nim/v/vector2.nim`](../../../nim/v/vector2.nim) |
| Odin | [`odin/v/vector2.odin`](../../../odin/v/vector2.odin) |
| Rust | [`rust/v/vector2.rs`](../../../rust/v/vector2.rs) |
| V | [`v/v/vector2.v`](../../../v/v/vector2.v) |
| Zig | [`zig/v/vector2.zig`](../../../zig/v/vector2.zig) |
