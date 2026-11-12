# Trapping rain water on a 2-D terrain

This benchmark computes how much water a bounded integer height map retains when water can escape from any boundary cell. The primary algorithm seeds all boundary cells into a min-heap, then visits inward in increasing effective escape height. When a cell is reached from level `L`, its escape level is `max(L, height[cell])`; the difference is its retained volume.

The local `trapped_rainwater` and `trapped_rainwater_two_pointer` packages operate on a one-dimensional height sequence. `flood_fill` replaces one equal-valued connected region. The multigrid benchmark solves a numerical correction problem, while the SPLASH-2 water packages model molecular pair interactions. Those contracts do not compute terrain retention by boundary escape levels.

## Contract

The exported symbol is `trapping_rain_water_ii` with the `i64_array_scalar` ABI. Input is `[R,C,heights row-major]`, where `1<=R,C<=8`, every height is an integer in `[0,1000]`, and exact input length is `2+R*C` (at most 66 signed i64 values). Four-directional adjacency connects cells. A boundary cell is any cell in the first or last row or column.

The result is the total retained volume as a signed i64. A grid with one row or one column retains zero. Malformed input returns `-1`. The maximum possible result in this profile is 36,000.

The independent oracle handles each interior cell separately: it binary-searches the distinct terrain elevations and uses a threshold-constrained BFS to find the lowest level at which that cell can reach a boundary. This differs from the primary global priority-queue flood.

## Provenance and rights

The public [LeetCode title/topic entry, “Trapping Rain Water II”](https://leetcode.com/problems/trapping-rain-water-ii/) was used only to discover the topic. No statement, examples, tests, submissions, or site code were used. The contract, fixtures, algorithms, and ports are clean-room work; no third-party source-code license is asserted.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary oracle](../../trapping_rain_water_ii_oracle.py), the [independent verifier](../../trapping_rain_water_ii_verifier_oracle.py), and the package-local static [inventory checker](../../check_trapping_rain_water_ii_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/trapping_rain_water_ii.c`](../../../c/t/trapping_rain_water_ii.c) |
| C3 | [`c3/t/trapping_rain_water_ii.c3`](../../../c3/t/trapping_rain_water_ii.c3) |
| C++ | [`cpp/t/trapping_rain_water_ii.cpp`](../../../cpp/t/trapping_rain_water_ii.cpp) |
| Elisa | [`elisa/t/trapping_rain_water_ii.elisa`](../../../elisa/t/trapping_rain_water_ii.elisa) |
| Mojo | [`mojo/t/trapping_rain_water_ii.mojo`](../../../mojo/t/trapping_rain_water_ii.mojo) |
| Nim | [`nim/t/trapping_rain_water_ii.nim`](../../../nim/t/trapping_rain_water_ii.nim) |
| Odin | [`odin/t/trapping_rain_water_ii.odin`](../../../odin/t/trapping_rain_water_ii.odin) |
| Rust | [`rust/t/trapping_rain_water_ii.rs`](../../../rust/t/trapping_rain_water_ii.rs) |
| V | [`v/t/trapping_rain_water_ii.v`](../../../v/t/trapping_rain_water_ii.v) |
| Zig | [`zig/t/trapping_rain_water_ii.zig`](../../../zig/t/trapping_rain_water_ii.zig) |
