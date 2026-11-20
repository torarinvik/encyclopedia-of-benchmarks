# K-mismatch within-factor copy propagation

This package isolates the third-stage copy propagation in the Chapter 24
approximate-repetition method. It starts from supplied Lempel–Ziv factors and
earlier-stage repetition records; it does not construct the block-head or
binary-division seed sets and does not claim to enumerate all maximal
repetitions. Those stages have separate profiles in
[`k_repetition_block_head_pair_pass`](../k_repetition_block_head_pair_pass/README.md)
and [`k_repetition_binary_division_kernel`](../k_repetition_binary_division_kernel/README.md).

## Contract

ABI: `i64_array_bytes_output`; exported symbol:
`k_repetition_within_factor_copy_propagation`.

The exact input frame is
`[n,K,text[n],factor_count,(start,end_exclusive,copy_start)*factor_count,seed_count,(start,end_exclusive,period,mismatches)*seed_count]`.
The text length is `1..16`, `K` is `0..3`, symbols are `0..5`, and the final
symbol occurs nowhere earlier. Factors must be the copy-overlap LZ
factorization: each noninitial factor is the shortest prefix of the remaining
suffix that has no earlier occurrence. Its supplied `copy_start` must be an
earlier occurrence of the factor prefix with maximal possible length; any
valid tied occurrence is accepted. A zero-length copied prefix uses `-1`.
The first factor is `(0,1,-1)`. Half-open factor intervals partition the text.

The seed rows are already-discovered globally maximal K-mismatch records.
Each row has length at least twice its positive period, exactly the stated
number of Hamming mismatches between period-shifted symbols, and cannot be
extended by one symbol on either side while staying within budget. Seed rows
may be repeated; the algorithm treats them as a set keyed by
`(start,end_exclusive,period)`.

Factors are processed left-to-right. For a factor `[a,b)` with earlier copy
start `c`, its copied prefix is `[c,c+(b-a-1))` and the shift is `a-c`.
For each target start `j` in `[a+1,b-2]`, the algorithm looks up seed or previously propagated
records starting at `j-(a-c)`. It uses only the sorted list prefix whose
end-exclusive position is within the copied prefix, shifts those records by
`a-c`, and inserts the shifted records at `j`. A shifted record is retained
only when its end-exclusive position is at most `b-2`; thus it lies inside
the copied prefix and does not touch the factor head or the character just
before it. Period and mismatch count are unchanged. Newly inserted records
remain available to later positions, which handles overlapping LZ copies.
Since the candidate and its one-symbol extension comparisons stay inside
text copied exactly from the source prefix, both mismatch count and
maximality are preserved. Identical triples are emitted once; output contains
only newly added triples and does not echo the seed set.

The output is a little-endian signed-64 byte stream:
`[record_count,(start,end_exclusive,period,mismatches)*record_count]`, sorted
by start, end-exclusive position, period, then mismatch count. Positions are
zero-based. Malformed input returns `-1`; null output or insufficient capacity
returns `-2`, and errors write no bytes. The whole input is validated before
the output-capacity check.

The maximum factor count is 16. The maximum number of distinct seed or output
triples is
`sum((n-2p+1)(n-2p+2)/2 for p=1..floor(n/2)) = 372` at `n=16`. Therefore the
maximum valid input is 1,556 i64 words, one additional parseable word is
reserved for trailing-data rejection, and the maximum output is 11,912 bytes.
Workspace is capped at 16,384 bytes, excluding caller buffers. In the widest
fixed-array representation, 372 four-field records use at most 11,904 bytes;
the two 2,448-bit membership maps use 624 bytes, and the text/factor arrays,
counters, and traversal locals fit within the remaining allowance.

## Complexity

The primary validates LZ pointers and seeds with bounded direct scans, then
uses ordered per-start lists for copy propagation. Its worst-case work is
`O(n^3 + n^2 R + R^2)` for `n<=16` and at most `R=372` records; storage is `O(R)`.
The independent reference directly checks earlier occurrences for each
factor and scans the whole active record set for each target position,
requiring `O(n^3 + n^2 R + R^2)` bounded work and `O(R)` storage. The formulas
describe this bounded profile; neither reference measures construction of the
full Chapter 24 pipeline.

## References and provenance

Chapter context: Gregory Kucherov and Dina Sokol, “Approximate Tandem
Repeats,” *Encyclopedia of Algorithms*, Chapter 24,
[DOI 10.1007/978-1-4939-2864-4_24](https://doi.org/10.1007/978-1-4939-2864-4_24).

Operational sources: Kolpakov and Kucherov, “Finding Approximate Repetitions
under Hamming Distance,” INRIA Research Report RR-4163 (2001), §3, third
stage ([archive copy](https://inria.hal.science/inria-00072459v1/document));
and Roman Kolpakov and Gregory Kucherov, “Finding Maximal Repetitions
in a Word in Linear Time,” FOCS 1999, §4,
[DOI 10.1109/SFFCS.1999.814634](https://doi.org/10.1109/SFFCS.1999.814634).
The latter supplies the earlier-copy record-bucket recovery mechanism; the
Chapter 24 text supplies the K-mismatch stage boundary rule. The package
implements only the propagation stage over explicitly supplied inputs.
Algorithm ideas and definitions informed this clean-room implementation;
source code, examples, and tests were not copied. See [RIGHTS.md](RIGHTS.md).

## Package files

The primary and structurally independent references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The bounded fixtures are in
[`workload.json`](workload.json); package-local static helpers are
[`verify_workload.py`](verify_workload.py) and
[`check_inventory.py`](check_inventory.py). The `i64_array_bytes_output`
suite, shared catalog, and Chapter 24 crosswalk include this profile.

| Language | Source |
|---|---|
| C | [`c/k/k_repetition_within_factor_copy_propagation.c`](../../../c/k/k_repetition_within_factor_copy_propagation.c) |
| C3 | [`c3/k/k_repetition_within_factor_copy_propagation.c3`](../../../c3/k/k_repetition_within_factor_copy_propagation.c3) |
| C++ | [`cpp/k/k_repetition_within_factor_copy_propagation.cpp`](../../../cpp/k/k_repetition_within_factor_copy_propagation.cpp) |
| Elisa | [`elisa/k/k_repetition_within_factor_copy_propagation.elisa`](../../../elisa/k/k_repetition_within_factor_copy_propagation.elisa) |
| Mojo | [`mojo/k/k_repetition_within_factor_copy_propagation.mojo`](../../../mojo/k/k_repetition_within_factor_copy_propagation.mojo) |
| Nim | [`nim/k/k_repetition_within_factor_copy_propagation.nim`](../../../nim/k/k_repetition_within_factor_copy_propagation.nim) |
| Odin | [`odin/k/k_repetition_within_factor_copy_propagation.odin`](../../../odin/k/k_repetition_within_factor_copy_propagation.odin) |
| Rust | [`rust/k/k_repetition_within_factor_copy_propagation.rs`](../../../rust/k/k_repetition_within_factor_copy_propagation.rs) |
| V | [`v/k/k_repetition_within_factor_copy_propagation.v`](../../../v/k/k_repetition_within_factor_copy_propagation.v) |
| Zig | [`zig/k/k_repetition_within_factor_copy_propagation.zig`](../../../zig/k/k_repetition_within_factor_copy_propagation.zig) |

