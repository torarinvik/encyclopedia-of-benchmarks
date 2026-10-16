# Count-min sketch with width-one collisions

This package isolates the width-one behavior shared by the pinned C# and Rust count-min sketches. With width 1 and depth 3, every key maps to the only counter in every row. Unit inserts therefore raise all three rows equally, and every query returns the total number of inserts so far. Rust's randomized hash seeds do not affect this result.

Pinned sources:

- C#: [TheAlgorithms/C-Sharp `CountMinSketch.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Probabilistic/CountMinSketch.cs)
- Rust: [TheAlgorithms/Rust `count_min_sketch.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/probabilistic/count_min_sketch.rs)

## Contract

Input is a signed 64-bit array `[operation_count, (operation, key)...]`. The operation count is 0 through 256. Operation `0` inserts one occurrence; operation `1` queries the estimate. Keys are restricted to -1,000,000 through 1,000,000. The sketch has fixed width 1 and depth 3. This key range also keeps the C# source's row-index multiplication within signed 32-bit range.

Output contains one little-endian signed 64-bit estimate for each query, in operation order. A valid empty or insert-only stream returns 0 bytes. The function returns the output byte count, `-1` for malformed or out-of-range input, and `-2` when the output buffer is too small. A null output pointer is accepted when there are no queries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/count_min_sketch_width_one_collision.c`](../../../c/c/count_min_sketch_width_one_collision.c) |
| C3 | [`c3/c/count_min_sketch_width_one_collision.c3`](../../../c3/c/count_min_sketch_width_one_collision.c3) |
| C++ | [`cpp/c/count_min_sketch_width_one_collision.cpp`](../../../cpp/c/count_min_sketch_width_one_collision.cpp) |
| Elisa | [`elisa/c/count_min_sketch_width_one_collision.elisa`](../../../elisa/c/count_min_sketch_width_one_collision.elisa) |
| Nim | [`nim/c/count_min_sketch_width_one_collision.nim`](../../../nim/c/count_min_sketch_width_one_collision.nim) |
| Odin | [`odin/c/count_min_sketch_width_one_collision.odin`](../../../odin/c/count_min_sketch_width_one_collision.odin) |
| Rust | [`rust/c/count_min_sketch_width_one_collision.rs`](../../../rust/c/count_min_sketch_width_one_collision.rs) |
| V | [`v/c/count_min_sketch_width_one_collision.v`](../../../v/c/count_min_sketch_width_one_collision.v) |
| Zig | [`zig/c/count_min_sketch_width_one_collision.zig`](../../../zig/c/count_min_sketch_width_one_collision.zig) |
