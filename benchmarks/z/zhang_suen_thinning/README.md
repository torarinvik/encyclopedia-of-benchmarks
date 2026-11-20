# Zhang-Suen thinning

Thin a rectangular binary image to a skeleton with the Zhang-Suen two-subiteration algorithm.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `zhang_suen_thinning`.
- Input is `[rows, columns, pixels...]`, with row-major binary pixels.
- Both dimensions are in `1..32`; the input contains exactly `2 + rows*columns` signed-i64 values, and each pixel is 0 or 1.
- A pixel on the outermost image border is immutable. Only pixels with all eight in-image neighbors are tested. This follows the task's full-neighborhood boundary rule.
- For each phase, inspect the current image and mark every eligible foreground pixel before deleting any marked pixel. Phase 1 requires 2–6 black neighbors, exactly one circular 0-to-1 transition in the clockwise neighbor ring, and `P2*P4*P6 = 0`, `P4*P6*P8 = 0`. Phase 2 uses the same neighbor-count and transition rules, with `P2*P4*P8 = 0`, `P2*P6*P8 = 0`. Neighbors are numbered `P2` north, then `P3` northeast, `P4` east, `P5` southeast, `P6` south, `P7` southwest, `P8` west, and `P9` northwest.
- Repeat both phases in order until neither phase removes a pixel. Output is one byte per final pixel in row-major order, and the return value is the number of bytes written.
- Invalid input returns `-1`. Insufficient output capacity returns `-2` without writing. At most 1,024 pixels and output bytes are accepted.

The primary reference marks candidates in a flat scratch grid and then clears them. The independent reference rebuilds a tuple-of-rows image after each phase. Both use 2,048 bytes of conceptual scratch space in the language ports. A nonterminal full round removes at least one foreground pixel, so at most `rows*columns` rounds occur. With `V=rows*columns`, the time bound is `O(V²)` and auxiliary space is `O(V)`.

This is distinct from the cBench SUSAN edges profile, which performs a one-pass, edge-response-specific thinning step after SUSAN edge detection. It also differs from single-generation cellular automata: Zhang-Suen marks and deletes boundary pixels according to two topology-preserving directional predicates and iterates to a fixed point.

See [workload](workload.json), [primary reference](primary_oracle.py), [independent reference](independent_oracle.py), [static inventory](INVENTORY.md), and [rights/provenance](RIGHTS.md). Source attribution: RosettaGit, [Zhang-Suen thinning algorithm](https://rosettagit.org/tasks/zhang-suen-thinning-algorithm/); algorithm description only.

## Language ports

| Language | Source |
|---|---|
| C | [`c/z/zhang_suen_thinning.c`](../../../c/z/zhang_suen_thinning.c) |
| C3 | [`c3/z/zhang_suen_thinning.c3`](../../../c3/z/zhang_suen_thinning.c3) |
| C++ | [`cpp/z/zhang_suen_thinning.cpp`](../../../cpp/z/zhang_suen_thinning.cpp) |
| Elisa | [`elisa/z/zhang_suen_thinning.elisa`](../../../elisa/z/zhang_suen_thinning.elisa) |
| Mojo | [`mojo/z/zhang_suen_thinning.mojo`](../../../mojo/z/zhang_suen_thinning.mojo) |
| Nim | [`nim/z/zhang_suen_thinning.nim`](../../../nim/z/zhang_suen_thinning.nim) |
| Odin | [`odin/z/zhang_suen_thinning.odin`](../../../odin/z/zhang_suen_thinning.odin) |
| Rust | [`rust/z/zhang_suen_thinning.rs`](../../../rust/z/zhang_suen_thinning.rs) |
| V | [`v/z/zhang_suen_thinning.v`](../../../v/z/zhang_suen_thinning.v) |
| Zig | [`zig/z/zhang_suen_thinning.zig`](../../../zig/z/zhang_suen_thinning.zig) |
