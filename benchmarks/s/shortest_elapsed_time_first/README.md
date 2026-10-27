# Shortest elapsed time first (SETF)

This package implements the chapter's non-clairvoyant SETF policy: at every
decision point, run a released unfinished job that has received the least
service so far. Equal attained-service values are resolved by smaller input
index. Job sizes are used only to detect completion; they do not affect which
job is selected. This is distinct from SRPT, which selects the least remaining
processing time.

The bounded profile uses integer release times (0–16), integer service sizes
(1–12), and at most eight jobs. It makes one scheduling decision per unit of
service, so the tie rule defines a deterministic discrete-time trace. The
output is one byte per time unit through completion: `0` means idle; values
`1..8` identify jobs `0..7`. Maximum trace length is 112 bytes. Malformed
input returns `-1`; null output or insufficient capacity returns `-2` without
writes.

The primary oracle scans the ready set at each time step. The independent
verifier uses a priority heap and pushes a job back after each service slice.
The profile measures a bounded execution trace, not competitive ratios or
continuous processor sharing.

Source: “Shortest Elapsed Time First Scheduling,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_369`](https://doi.org/10.1007/978-1-4939-2864-4_369).
The package contains no copied book prose, figures, or code; see
[RIGHTS.md](RIGHTS.md).

## Workload and ports

The [workload](workload.json) covers no jobs, equal-service ties, a distinction
from SRPT, arrivals after idle time, maximum output, malformed inputs, null
buffers, and capacity errors.

| Language | Port |
| --- | --- |
| C | [`c/s/shortest_elapsed_time_first.c`](../../../c/s/shortest_elapsed_time_first.c) |
| C3 | [`c3/s/shortest_elapsed_time_first.c3`](../../../c3/s/shortest_elapsed_time_first.c3) |
| C++ | [`cpp/s/shortest_elapsed_time_first.cpp`](../../../cpp/s/shortest_elapsed_time_first.cpp) |
| Elisa | [`elisa/s/shortest_elapsed_time_first.elisa`](../../../elisa/s/shortest_elapsed_time_first.elisa) |
| Nim | [`nim/s/shortest_elapsed_time_first.nim`](../../../nim/s/shortest_elapsed_time_first.nim) |
| Odin | [`odin/s/shortest_elapsed_time_first.odin`](../../../odin/s/shortest_elapsed_time_first.odin) |
| Rust | [`rust/s/shortest_elapsed_time_first.rs`](../../../rust/s/shortest_elapsed_time_first.rs) |
| V | [`v/s/shortest_elapsed_time_first.v`](../../../v/s/shortest_elapsed_time_first.v) |
| Zig | [`zig/s/shortest_elapsed_time_first.zig`](../../../zig/s/shortest_elapsed_time_first.zig) |
