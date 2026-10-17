# K-centers

## Contract

This benchmark follows Java `KCenters.findKCenters` on a bounded distance matrix. Input is `[point_count, center_count, row-major n*n distances]`, with 1..8 points, 1..n centers, symmetric distances with a zero diagonal, and entries in `0..1,000,000`. Symmetry and the zero diagonal define a valid distance matrix; no Euclidean or triangle-inequality condition is imposed.

The pinned farthest-first procedure starts with point 0, repeatedly chooses the first unselected point with the greatest current nearest-center distance, and updates each point's stored distance. The source initializes every `maxDist` entry to `Integer.MAX_VALUE` but does not set entry 0 to zero. Preserve that behavior: with `center_count == 1`, the result is `2147483647`, including when there is only one point. For two or more centers, entry 0 tracks distances to the newly selected centers but never includes its zero distance to the initial center; the result is the maximum of the source's final `maxDist` state, including that quirk. Malformed input or values outside the declared domain return `-1`.

## Workload

[`workload.json`](workload.json) includes the one-center source behavior, first-index tie resolution, ordinary farthest-first choices, all points selected, matrix and input boundaries, and invalid shapes or values.

## TheAlgorithms reference

- Java [`KCenters.findKCenters`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/KCenters.java) uses deterministic farthest-first selection over the supplied distance matrix.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/k/kcenters.c](../../../c/k/kcenters.c) |
| C3 | [c3/k/kcenters.c3](../../../c3/k/kcenters.c3) |
| C++ | [cpp/k/kcenters.cpp](../../../cpp/k/kcenters.cpp) |
| Elisa | [elisa/k/kcenters.elisa](../../../elisa/k/kcenters.elisa) |
| Nim | [nim/k/kcenters.nim](../../../nim/k/kcenters.nim) |
| Odin | [odin/k/kcenters.odin](../../../odin/k/kcenters.odin) |
| Rust | [rust/k/kcenters.rs](../../../rust/k/kcenters.rs) |
| V | [v/k/kcenters.v](../../../v/k/kcenters.v) |
| Zig | [zig/k/kcenters.zig](../../../zig/k/kcenters.zig) |
