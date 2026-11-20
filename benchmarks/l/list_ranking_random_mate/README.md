# Weighted list ranking by Random_Mate

This profile implements the classic randomized `Random_Mate` list-ranking
rule described in Algorithm 2.2 of the cited Miller, Reid-Miller, and Modugno
exposition. It benchmarks a distinct method for the same list-ranking problem
covered by the Encyclopedia of Algorithms chapter. It repeatedly
assigns male/female bits to the active list and splices out a successor when
the current node is female and that successor is male. The predecessor adds
the spliced node's accumulated distance, and removed nodes are restored in
reverse round order.

## Input and result

The exported symbol is `list_ranking_random_mate`; the ABI is
`i64_array_bytes_output`. Input is
`[n, head, weights_by_id..., successors_by_id..., rounds, coin_bits...]`.
There are at most 8 nodes and 32 rounds. Weights are in `1..10000`, successors
form one path beginning at `head`, and `-1` marks the tail. The tape has exactly
`rounds*n` bits in round-major, node-ID order; each bit is `0` for female or
`1` for male. The tail and already removed nodes still have tape slots; their
bits are ignored unless the tail is inspected as an active successor. All bits
must be 0 or 1.

`rounds` is a cap. After the list contracts to one active node, remaining tape
rows are ignored. If the cap expires while more than one node remains, the
frame is invalid and returns `-1`. Thus deterministic supplied tapes make the
randomized selection reproducible without changing the round-by-round rule.
The profile gives every active node a supplied sex bit, including the current
tail when a predecessor reads it as a target; the cited Algorithm 2.2
pseudocode leaves that tail-bit convention implicit.
The maximum frame length is 275 signed 64-bit values.

The result is one little-endian signed 64-bit inclusive suffix rank per node,
in node-ID order: the sum of weights from that node through the tail. Invalid
input returns `-1`; a null output or capacity below `8*n` returns `-2` without
writing.
The source initializes unit ranks; this benchmark generalizes its same
aggregation recurrence to positive supplied node weights.

## Work and source

Each bounded round scans the fixed node arrays, so this serial replay takes
`O(n*rounds)` time and `O(n)` space, with `n<=8` and `rounds<=32`. The profile
measures the source's randomized contraction decisions on an explicit tape; it
does not claim parallel PRAM depth or expected runtime for one supplied tape.
The direct-traversal verifier computes suffix sums independently of
contraction.

Book context: Riko Jacob, Ulrich Meyer, and Laura Toma, “List Ranking,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_592`](https://doi.org/10.1007/978-1-4939-2864-4_592).
The clean-room ports follow Algorithm 2.2 in the Miller, Reid-Miller, and
Modugno chapter [“List Ranking and Parallel Tree Contraction”](https://www.cs.cmu.edu/~glmiller/Publications/Papers/ReMiMo93.pdf).
Only the algorithmic method was used; no source implementation or prose was
copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/l/list_ranking_random_mate.c`](../../../c/l/list_ranking_random_mate.c) |
| C3 | [`c3/l/list_ranking_random_mate.c3`](../../../c3/l/list_ranking_random_mate.c3) |
| C++ | [`cpp/l/list_ranking_random_mate.cpp`](../../../cpp/l/list_ranking_random_mate.cpp) |
| Elisa | [`elisa/l/list_ranking_random_mate.elisa`](../../../elisa/l/list_ranking_random_mate.elisa) |
| Mojo | [`mojo/l/list_ranking_random_mate.mojo`](../../../mojo/l/list_ranking_random_mate.mojo) |
| Nim | [`nim/l/list_ranking_random_mate.nim`](../../../nim/l/list_ranking_random_mate.nim) |
| Odin | [`odin/l/list_ranking_random_mate.odin`](../../../odin/l/list_ranking_random_mate.odin) |
| Rust | [`rust/l/list_ranking_random_mate.rs`](../../../rust/l/list_ranking_random_mate.rs) |
| V | [`v/l/list_ranking_random_mate.v`](../../../v/l/list_ranking_random_mate.v) |
| Zig | [`zig/l/list_ranking_random_mate.zig`](../../../zig/l/list_ranking_random_mate.zig) |

The [workload](workload.json), primary contraction oracle, and independent
direct-traversal verifier are wired into the byte-output suite.
