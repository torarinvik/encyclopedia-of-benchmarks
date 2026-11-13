# Multi-probe LSH query-directed probe sequence (in progress)

This profile isolates the query-directed perturbation generator for one hash
table. The caller supplies each projection's distance to its lower bin
boundary. For each coordinate, its upper-boundary distance is the bin width
minus that value. Sort the two signed choices per coordinate by distance,
coordinate, then sign (negative before positive). Each nonempty subset of
sorted choices represents a perturbation; subsets containing both signs of a
coordinate are invalid. Its score is the sum of squared choice distances.

The `i64_array_bytes_output` input is `[m,width,t,lower_distance_0,...]`,
where `1<=m<=4`, `1<=width<=1000`, distances are integers in `0..width`,
`0<=t<=3^m-1`, and the length is exactly `3+m`. Return the first `t` valid
nonempty perturbations in ascending `(score, number of choices, mask)` order.
The mask is one byte: bit `j` refers to the j-th sorted signed choice, with
the first choice at bit zero. Output has exactly `t` bytes, with no header.
Invalid input returns `-1`; a null or too-small output returns `-2`, even when
`t=0`. Errors do not write.

The intended algorithm keeps a min-heap of subsets. Beginning with the first
choice, each popped subset generates a shifted child (replace its highest set
bit with the next bit) and an expanded child (add that next bit). Discard
invalid sets only when emitting, so their descendants remain reachable. The
ordering's population-count and mask tie breaks ensure a parent precedes a
same-score child. Heap space is O(K), and time is O(m log m + K log K + Km),
where K is the number of popped sets including invalid sets; K<=2^(2m)-1.
This is the probe-sequence kernel, not a full ANN index or a reproduction of
Ferret's complete pipeline.

Source: Lv et al., [“Multi-Probe LSH: Efficient Indexing for High-Dimensional
Similarity Search”](https://www.cs.princeton.edu/cass/papers/mplsh_vldb07.pdf)
and the [PARSEC technical report](https://www.cs.princeton.edu/techreports/2010/890.pdf).
The publications are used for algorithm descriptions; no code, prose or
fixtures are copied.

**Status:** two oracle drafts, a workload, ten language drafts and byte-output
suite registration are present. All remain unexecuted and need validation.
The suite defines exhaustive small-distance comparisons, prefix and maximum
output cases, and package source-path checks.

| Language | Draft |
| --- | --- |
| C | [`c/m/multiprobe_lsh_probe_sequence.c`](../../../c/m/multiprobe_lsh_probe_sequence.c) |
| C3 | [`c3/m/multiprobe_lsh_probe_sequence.c3`](../../../c3/m/multiprobe_lsh_probe_sequence.c3) |
| C++ | [`cpp/m/multiprobe_lsh_probe_sequence.cpp`](../../../cpp/m/multiprobe_lsh_probe_sequence.cpp) |
| Elisa | [`elisa/m/multiprobe_lsh_probe_sequence.elisa`](../../../elisa/m/multiprobe_lsh_probe_sequence.elisa) |
| Mojo | [`mojo/m/multiprobe_lsh_probe_sequence.mojo`](../../../mojo/m/multiprobe_lsh_probe_sequence.mojo) |
| Nim | [`nim/m/multiprobe_lsh_probe_sequence.nim`](../../../nim/m/multiprobe_lsh_probe_sequence.nim) |
| Odin | [`odin/m/multiprobe_lsh_probe_sequence.odin`](../../../odin/m/multiprobe_lsh_probe_sequence.odin) |
| Rust | [`rust/m/multiprobe_lsh_probe_sequence.rs`](../../../rust/m/multiprobe_lsh_probe_sequence.rs) |
| V | [`v/m/multiprobe_lsh_probe_sequence.v`](../../../v/m/multiprobe_lsh_probe_sequence.v) |
| Zig | [`zig/m/multiprobe_lsh_probe_sequence.zig`](../../../zig/m/multiprobe_lsh_probe_sequence.zig) |
