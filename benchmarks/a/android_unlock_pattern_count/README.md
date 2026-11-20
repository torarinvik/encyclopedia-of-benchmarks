# Android unlock pattern count

Count legal patterns of exactly `L` points on Android's canonical 3×3 unlock
grid. This clean-room profile was discovered from the public Codewars title
“Screen Locking Patterns” in its [Algorithms + Graph Theory listing](https://www.codewars.com/kata?tags=Algorithms%2CGraph+Theory);
the title and tags were used only for discovery.

## Contract

The `i64_array_scalar` input is `[L]`, with exactly one signed 64-bit word and
`4 <= L <= 9`. Points are numbered `0` through `8` in row-major order. Return
the number of valid ordered patterns using exactly `L` distinct points. Null
input, empty or trailing-word frames, and lengths outside 4–9 return `-1`.

A pattern cannot revisit a point, and every move is a straight segment. Any
grid point strictly inside a move segment must already have appeared earlier
in the pattern. On a 3×3 grid, an eligible segment may have one midpoint; a
move that crosses that midpoint is legal only after the midpoint was visited.

## Algorithms and references

The primary recursively extends each prefix from all nine possible starting
points. A 9-bit mask tracks visited points, and each candidate extension checks
its possible midpoint before recursing. The independent reference scans all
length-`L` permutations and tests each segment's interior lattice points from
its coordinate step vector. The largest independent scan has `9!` candidates.

The Android 3×3 rules and enumeration context are described by Uellenbeck et
al., [“Quantifying the Security of Graphical Passwords: The Case of Android
Unlock Patterns”](https://doi.org/10.1145/2508859.2516700), and Lee et al.,
[“A Visibility-Based Lower Bound for Android Unlock Patterns”](https://doi.org/10.1587/transinf.2016EDL8196).
The per-length counts are listed in [OEIS A163889](https://oeis.org/A163889).
These sources provide method context and expected counts; their code and prose
are not reused.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md). The ten ports use the shared scalar ABI. No
programs, tests, checkers, scripts, builds, compilers, profilers, or benchmarks
have been run.

| Language | Source |
| --- | --- |
| C | [`c/a/android_unlock_pattern_count.c`](../../../c/a/android_unlock_pattern_count.c) |
| C3 | [`c3/a/android_unlock_pattern_count.c3`](../../../c3/a/android_unlock_pattern_count.c3) |
| C++ | [`cpp/a/android_unlock_pattern_count.cpp`](../../../cpp/a/android_unlock_pattern_count.cpp) |
| Elisa | [`elisa/a/android_unlock_pattern_count.elisa`](../../../elisa/a/android_unlock_pattern_count.elisa) |
| Mojo | [`mojo/a/android_unlock_pattern_count.mojo`](../../../mojo/a/android_unlock_pattern_count.mojo) |
| Nim | [`nim/a/android_unlock_pattern_count.nim`](../../../nim/a/android_unlock_pattern_count.nim) |
| Odin | [`odin/a/android_unlock_pattern_count.odin`](../../../odin/a/android_unlock_pattern_count.odin) |
| Rust | [`rust/a/android_unlock_pattern_count.rs`](../../../rust/a/android_unlock_pattern_count.rs) |
| V | [`v/a/android_unlock_pattern_count.v`](../../../v/a/android_unlock_pattern_count.v) |
| Zig | [`zig/a/android_unlock_pattern_count.zig`](../../../zig/a/android_unlock_pattern_count.zig) |
