# K-mismatch repetition block-head pair pass

This package isolates the first, paired-block stage in Kolpakov and Kucherov's
search for maximal K-mismatch globally defined repetitions. It complements
[`k_repetition_binary_division_kernel`](../k_repetition_binary_division_kernel/README.md),
which benchmarks the later intra-block binary-division stage. The profile does
not claim to return the union of all stages or all globally maximal repetitions.

## Contract

ABI: `i64_array_bytes_output`; exported symbol:
`k_repetition_block_head_pair_pass`.

Input is exactly `[n,K,w0,...,w(n-1)]`, where `1<=n<=24`, `0<=K<=3`, and every
symbol is in `0..4`. The final symbol must occur nowhere earlier. The maximum
valid frame is 26 signed 64-bit words; one additional word is parseable for a
trailing-data rejection probe.

Build the copy-overlap Lempel-Ziv factorization, grouping consecutive factors
into blocks of at most `K+2`. For every adjacent block pair `(B_i,B_(i+1))`,
let `[a,b)` be the text interval covered by the pair and `s=b-a`. Form the
context `text[max(0,a-s):b]`. Run the report's Algorithm 1 in this context at
the final character of `B_i`; keep results whose interval contains that
character or either neighbor, then discard results touching the final
character of `B_(i+1)`. Repetitions found in different contexts form a set.
The final block is skipped if it has no successor.

“Touches `h`” means an inclusive repetition interval `[start,end]` satisfies
`start<=h+1 && end>=h-1`. Algorithm 1 uses the paper's split of the mismatch
budget between forward and backward extensions; this bounded implementation
computes those extensions by direct scans. Maximality is with respect to the
selected context. The preceding suffix gives the pair context specified by
the paper's stage-one construction.

Output is a little-endian signed-64 byte stream:
`[record_count,(start,length,period,mismatches)...]`. Positions are zero-based;
records sort by start, length, period, then mismatch count. The bound counts all
possible `(start,end,period)` triples with `length>=2*period` at `n=24`: 1,222
records and 39,112 bytes including the count.

Malformed input returns `-1`. Null output or insufficient capacity returns
`-2`; errors write no bytes. Implementations validate the full input before
checking output capacity. Workspace is capped at 8,192 bytes, excluding caller
buffers. The 7,488-bit deduplication table occupies 936 bytes; text, factors,
context, reverse scratch, and scalar state fit within the remaining budget.

## Complexity

With direct bounded scans, the primary takes `O((K+1)n^3)` time for
factorization and Algorithm 1 across at most `n` adjacent-block contexts.
Serialization can add `O(n^4)` time because it recounts mismatches for every
marked `(start,end,period)` triple. The candidate bitset uses `O(n^3)` bits;
text, factors, and context scratch use `O(n)` space. The independent reference
enumerates `O(n^3)` interval/period candidates per context and directly
recounts up to `O(n)` mismatches per candidate, for `O(n^5)` worst-case time
across up to `O(n)` contexts. The profile is bounded at `n<=24` and `K<=3`.

## References and provenance

Chapter context: Gregory Kucherov and Dina Sokol, “Approximate Tandem
Repeats,” *Encyclopedia of Algorithms*, Chapter 24,
[DOI 10.1007/978-1-4939-2864-4_24](https://doi.org/10.1007/978-1-4939-2864-4_24).

Operational source: Roman Kolpakov and Gregory Kucherov, “Finding Approximate
Repetitions under Hamming Distance,” INRIA Research Report RR-4163 (2001), §3,
first block-head stage and Algorithm 1; journal version *Theoretical Computer
Science* 303(1), 135–156 (2003),
[DOI 10.1016/S0304-3975(02)00448-6](https://doi.org/10.1016/S0304-3975(02)00448-6).
The report's [open archive copy](https://inria.hal.science/inria-00072459v1/document)
contains the operational description. Sources inform algorithm ideas and
definitions only. The contract, implementations, and fixtures are clean-room
work; no source code or published examples were copied. See [RIGHTS.md](RIGHTS.md).

The primary reference uses direct forward/backward extension scans and the
paper's budget split. The independent reference enumerates each context's
interval/period candidates and checks one-symbol maximality by direct mismatch
counts. Pinned fixtures are in [workload.json](workload.json); static helpers
are [verify_workload.py](verify_workload.py) and
[check_inventory.py](check_inventory.py).

## Language sources

| Language | Source |
|---|---|
| C | [`c/k/k_repetition_block_head_pair_pass.c`](../../../c/k/k_repetition_block_head_pair_pass.c) |
| C3 | [`c3/k/k_repetition_block_head_pair_pass.c3`](../../../c3/k/k_repetition_block_head_pair_pass.c3) |
| C++ | [`cpp/k/k_repetition_block_head_pair_pass.cpp`](../../../cpp/k/k_repetition_block_head_pair_pass.cpp) |
| Elisa | [`elisa/k/k_repetition_block_head_pair_pass.elisa`](../../../elisa/k/k_repetition_block_head_pair_pass.elisa) |
| Mojo | [`mojo/k/k_repetition_block_head_pair_pass.mojo`](../../../mojo/k/k_repetition_block_head_pair_pass.mojo) |
| Nim | [`nim/k/k_repetition_block_head_pair_pass.nim`](../../../nim/k/k_repetition_block_head_pair_pass.nim) |
| Odin | [`odin/k/k_repetition_block_head_pair_pass.odin`](../../../odin/k/k_repetition_block_head_pair_pass.odin) |
| Rust | [`rust/k/k_repetition_block_head_pair_pass.rs`](../../../rust/k/k_repetition_block_head_pair_pass.rs) |
| V | [`v/k/k_repetition_block_head_pair_pass.v`](../../../v/k/k_repetition_block_head_pair_pass.v) |
| Zig | [`zig/k/k_repetition_block_head_pair_pass.zig`](../../../zig/k/k_repetition_block_head_pair_pass.zig) |

Shared suite, catalog, and chapter-crosswalk registration are left to the
repository integrator.
