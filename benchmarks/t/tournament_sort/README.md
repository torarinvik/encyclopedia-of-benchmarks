# Tournament sort

This package sorts a signed 32-bit integer vector with a winner tree. It uses the tournament-sort approach: place values in leaves, store the index of each subtree's smallest value in internal nodes, repeatedly emit the root winner, and update that winner's path to the root.

Input is `[count, values...]` in signed 64-bit slots. `count` is from 0 through 512, the vector must contain exactly `count` values after the header, and every value must fit signed 32-bit range. Malformed input returns `-1`.

Output is `[count, sorted_values...]` encoded as little-endian signed 64-bit values. The return value is the output byte length. A null output buffer or insufficient capacity returns `-2` without writing output. The benchmark normalizes Java's in-place generic sorting and Rust's returned vector to the same read-only input/output contract. Equal values are preserved; equal winners are resolved to the left side of the tree.

| Language | Port |
|---|---|
| C | [`c/t/tournament_sort.c`](../../../c/t/tournament_sort.c) |
| C3 | [`c3/t/tournament_sort.c3`](../../../c3/t/tournament_sort.c3) |
| C++ | [`cpp/t/tournament_sort.cpp`](../../../cpp/t/tournament_sort.cpp) |
| Elisa | [`elisa/t/tournament_sort.elisa`](../../../elisa/t/tournament_sort.elisa) |
| Nim | [`nim/t/tournament_sort.nim`](../../../nim/t/tournament_sort.nim) |
| Odin | [`odin/t/tournament_sort.odin`](../../../odin/t/tournament_sort.odin) |
| Rust | [`rust/t/tournament_sort.rs`](../../../rust/t/tournament_sort.rs) |
| V | [`v/t/tournament_sort.v`](../../../v/t/tournament_sort.v) |
| Zig | [`zig/t/tournament_sort.zig`](../../../zig/t/tournament_sort.zig) |

Pinned sources: [TheAlgorithms/Java `TournamentSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/TournamentSort.java) and [TheAlgorithms/Rust `tournament_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/tournament_sort.rs). See [`workload.json`](workload.json) for representative cases.
