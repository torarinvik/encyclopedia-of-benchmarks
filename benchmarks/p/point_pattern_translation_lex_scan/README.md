# Point Pattern Matching by Lexicographic Translation Scan

This profile implements the chapter's exact point pattern matching algorithm
for translations from *Point Pattern Matching*, Veli Mäkinen and Esko Ukkonen,
*Encyclopedia of Algorithms*, DOI 10.1007/978-1-4939-2864-4_296.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[pattern_count,target_count,pattern_xy...,target_xy...]`. Both point lists are
strictly lexicographically sorted by `(x,y)`, contain no duplicates, and use
coordinates in `[-16,16]`. The profile bounds the pattern to 1–6 points, the
target to 1–8 points, and requires `pattern_count<=target_count`.

For every target point in lexicographic order, the algorithm anchors the first
pattern point there and derives a translation. It then scans forward through
the target list to find each successive translated pattern point. The first
successful candidate is the lexicographically smallest successful translation
because target anchors are sorted and the same pattern point is used for every
candidate. The result is `[found,dx,dy]`; `found` is 1 with the translation, or
0 with `(0,0)` when no exact occurrence exists. The fixed output is 24 bytes.
Malformed input returns `-1`; null or undersized output returns `-2` without
writes.

This is distinct from the chapter's translation-voting profile
[`point_pattern_translation_voting`](../point_pattern_translation_voting/README.md):
the scan decides exact occurrence by ordered successive search instead of
counting every pattern-target translation pair. Both profiles cover exact
translation matching, while voting additionally reports largest common-set
overlap counts.

## Files

Nine ports are under `c/p`, `cpp/p`, `rust/p`, `c3/p`, `nim/p`, `odin/p`,
`elisa/p`, `v/p`, and `zig/p`; workload and primary/independent oracles are
included here and in `benchmarks/`.
