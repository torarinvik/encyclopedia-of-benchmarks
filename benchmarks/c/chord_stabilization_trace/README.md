# Chord stabilization trace (in progress)

This profile replays sequential Chord stabilization events on a supplied set
of nodes. For each scheduled node, inspect its successor's predecessor; adopt
that node as successor when it is strictly between the caller and the old
successor clockwise. Notify the resulting successor, which records the caller
as predecessor if it has no predecessor or the caller is strictly between its
current predecessor and itself clockwise. Events observe preceding events'
updates. This is distinct from the immutable, canonical-ring
[`p2p_chord_finger_lookup`](../../p/p2p_chord_finger_lookup/README.md).

Input to the `i64_array_bytes_output` ABI is
`[bits,n,q,ids[n],successor_indices[n],predecessor_indices[n],schedule[q]]`.
Here `1<=bits<=6`, `1<=n<=min(16,2^bits)`, `0<=q<=64`; IDs are strictly
increasing integers in `[0,2^bits)`. Successors and schedule entries are
node indices in `0..n-1`; predecessors are such indices or `-1` for absent.
Successor pointers may point to the caller. All indices are checked but the
initial links need not form a correct ring. For the open clockwise interval
`(a,b)`, equal endpoints include every distinct identifier other than `a`;
otherwise membership requires a positive clockwise distance from `a` that
is less than the distance from `a` to `b`.

Emit exactly `2*n` bytes: final successor indices in node order, then final
predecessor indices in node order, using byte `255` for absent. Invalid input
returns `-1`; null or insufficient output returns `-2` without writes. The
maximum valid input is 115 i64 words and output is 32 bytes. Validation and
replay take O(n+q) time and O(n) space.

This is a deterministic, atomic replay of the successor and predecessor
updates in [Stoica et al.'s Chord paper](https://pdos.csail.mit.edu/papers/ton%3Achord/paper-ton.pdf).
It does not implement network communication, join lookup, failures, finger
repair, concurrency or a convergence proof. The paper is an algorithm
reference; no source code, prose, examples or figures are copied.

**Status:** contract, workload, two references, ten language drafts and
byte-output suite registration are present. Nothing has been executed;
validation remains.
The verifier source defines exhaustive small states, a stable maximum-size
ring, and randomized bounded traces compared against both references.

| Language | Draft |
| --- | --- |
| C | [`c/c/chord_stabilization_trace.c`](../../../c/c/chord_stabilization_trace.c) |
| C3 | [`c3/c/chord_stabilization_trace.c3`](../../../c3/c/chord_stabilization_trace.c3) |
| C++ | [`cpp/c/chord_stabilization_trace.cpp`](../../../cpp/c/chord_stabilization_trace.cpp) |
| Elisa | [`elisa/c/chord_stabilization_trace.elisa`](../../../elisa/c/chord_stabilization_trace.elisa) |
| Mojo | [`mojo/c/chord_stabilization_trace.mojo`](../../../mojo/c/chord_stabilization_trace.mojo) |
| Nim | [`nim/c/chord_stabilization_trace.nim`](../../../nim/c/chord_stabilization_trace.nim) |
| Odin | [`odin/c/chord_stabilization_trace.odin`](../../../odin/c/chord_stabilization_trace.odin) |
| Rust | [`rust/c/chord_stabilization_trace.rs`](../../../rust/c/chord_stabilization_trace.rs) |
| V | [`v/c/chord_stabilization_trace.v`](../../../v/c/chord_stabilization_trace.v) |
| Zig | [`zig/c/chord_stabilization_trace.zig`](../../../zig/c/chord_stabilization_trace.zig) |
