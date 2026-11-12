# Sattolo Cycle Shuffle

Sattolo's algorithm shuffles positions into a single cycle. During the descending pass, it swaps position `remaining - 1` with a position chosen strictly below it. That restricted choice distinguishes the algorithm from Fisher–Yates, which permits the current position and generates unrestricted permutations. The algorithm is described and proved for ideal uniform choices in [Gries and Xue's correctness report](https://www.cs.cornell.edu/gries/TechReports/86-786.pdf) and [Wilson's algorithm overview](https://mathexp.eu/chyzak/Publications/RR-5542.pdf).

## Contract

Input is a signed 64-bit array `[seed, value...]`. The seed is in `1..=2,147,483,646`; there are at most 1,024 values, each in the signed i32 range. To make every port replay the same swaps, the benchmark uses the Park–Miller recurrence `state = (state * 48,271) mod 2,147,483,647`. For `remaining` from the value count down through 2, it swaps `remaining - 1` with `state mod (remaining - 1)`. Thus each choice is in `0..remaining-2`, as required by Sattolo's algorithm. The deterministic generator and modulo reduction define this benchmark's input stream; they are not a statistical test of the ideal random-choice algorithm.

Output is the resulting values as four-byte little-endian two's-complement i32 values. The return value is the number of values. Invalid input returns `-1`; insufficient output capacity returns `-2`. The shuffle takes `O(n)` time and uses `O(n)` storage for validated input. For distinct values and `n > 1`, the output positions form one cycle and therefore have no fixed points.

See [`workload.json`](workload.json) for representative vectors and [`benchmarks/sattolo_cycle_oracle.py`](../../sattolo_cycle_oracle.py) for the direct oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sattolo_cycle.c`](../../../c/s/sattolo_cycle.c) |
| C3 | [`c3/s/sattolo_cycle.c3`](../../../c3/s/sattolo_cycle.c3) |
| C++ | [`cpp/s/sattolo_cycle.cpp`](../../../cpp/s/sattolo_cycle.cpp) |
| Elisa | [`elisa/s/sattolo_cycle.elisa`](../../../elisa/s/sattolo_cycle.elisa) |
| Mojo | [`mojo/s/sattolo_cycle.mojo`](../../../mojo/s/sattolo_cycle.mojo) |
| Nim | [`nim/s/sattolo_cycle.nim`](../../../nim/s/sattolo_cycle.nim) |
| Odin | [`odin/s/sattolo_cycle.odin`](../../../odin/s/sattolo_cycle.odin) |
| Rust | [`rust/s/sattolo_cycle.rs`](../../../rust/s/sattolo_cycle.rs) |
| V | [`v/s/sattolo_cycle.v`](../../../v/s/sattolo_cycle.v) |
| Zig | [`zig/s/sattolo_cycle.zig`](../../../zig/s/sattolo_cycle.zig) |
