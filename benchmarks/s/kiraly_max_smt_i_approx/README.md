# Király MAX-SMTI 3/2 approximation

This bounded clean-room profile implements the local Deferred Acceptance
variation described in “Simpler Approximation for Stable Marriage,” Zoltán
Király, *Encyclopedia of Algorithms*, DOI 10.1007/978-1-4939-2864-4_676.
It solves a supplied instance of maximum stable matching with ties and
incomplete lists (MAX-SMTI). The result is the source algorithm's stable
matching, not a maximum-cardinality optimum certificate.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[men, women, men_rank[men][women], women_rank[women][men]]`, with both rank
matrices in row-major order. A rank of `-1` means unacceptable; nonnegative
ranks are weak-order groups, where lower is preferred and equal values denote
a tie. Acceptability must be mutual. Rank values are bounded to `0..5`; gaps
are allowed. Each side has 1–6 agents, so input is at most 74 signed 64-bit
values. The output is one little-endian i64 woman ID (or `-1` when unmatched)
per man, in man-ID order. It is at most 48 bytes. Invalid input returns `-1`;
a null or undersized output returns `-2` without writing output.

## Source rules and deterministic profile choices

All men begin as active lads. The lowest-ID active man proposes to his
favorite currently available acceptable woman. Within an original tied rank,
he prefers a maiden to an engaged woman; remaining ties use lower woman ID.
Women first use their weak-order rank. Within a tie, a bachelor outranks a lad;
remaining ties use lower man ID. An engaged woman is flighty exactly when her
fiancé is an uncertain lad, and then she prefers any certain suitor over that
fiancé regardless of their original ranks. An engaged lad is uncertain exactly
when his live list contains a woman with a strictly better original rank, or a
tied-rank maiden while his fiancé is engaged. Lower-ID tie-breaking chooses a
proposal but does not turn an otherwise indifferent woman into a
source-defined strict preference.

On rejection, a proposer deletes that woman from his live list. If an
uncertain lad is displaced, he keeps the woman who rejected him; otherwise he
deletes her. When a lad exhausts his live list, he becomes a bachelor, restores
his original list and reactivates. When a bachelor exhausts that restored list,
he becomes an inactive old bachelor. A bachelor remains a bachelor if engaged.
The source's three-proposals-per-acceptable-pair bound gives a finite
worst-case loop bound for these 6-by-6 instances.

This is algorithmically distinct from ordinary strict-preference
Gale–Shapley and from resident-oriented Hospitals/Residents deferred
acceptance. The package does not solve MAX-SMTI exactly or report the optimum.

## Package contents

The nine ports live under `c/s`, `cpp/s`, `rust/s`, `c3/s`, `nim/s`, `odin/s`,
`elisa/s`, `v/s` and `zig/s`. `workload.json` records bounded examples and
malformed/capacity cases. The package oracle and a separately written
verifier oracle provide expected bytes.
