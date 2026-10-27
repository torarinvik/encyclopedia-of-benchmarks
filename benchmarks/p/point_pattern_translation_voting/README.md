# Point-Pattern Translation Voting

This package profiles the chapter's translation-voting algorithm for Exact
Point Pattern Matching and Largest Common Point Set under translations from
“Point Pattern Matching,” Veli Mäkinen and Esko Ukkonen, *Encyclopedia of
Algorithms*, DOI 10.1007/978-1-4939-2864-4_296. It generates each translation
mapping a pattern point to a target point, sorts equal translations into vote
groups, and returns a maximum-vote translation.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[pattern_count,target_count,px0,py0,...,tx0,ty0,...]`. The pattern has 1–6
distinct points, the target has 1–8 distinct points, and all integral
coordinates are in `[-16,16]`. The maximum input is 30 i64 values. Output is
three i64 values `[maximum_votes,dx,dy]`; the matched subset is exactly the
pattern points whose translation `(x+dx,y+dy)` lies in the target set. If
several translations tie, the lexicographically smallest `(dx,dy)` is chosen.
Thus `maximum_votes == pattern_count` is an exact occurrence. Invalid input
returns `-1`; a null or undersized output returns `-2` without writing output.

The profile uses exact integer translation vectors. It excludes rotation,
scale, approximate-distance, and one-to-one matching variants discussed in
the chapter. The primary oracle sorts the pair-generated translation vectors
and counts equal runs; the independent verifier evaluates each candidate by
direct translated-point membership.

## Files

Nine ports live under `c/p`, `cpp/p`, `rust/p`, `c3/p`, `nim/p`, `odin/p`,
`elisa/p`, `v/p`, and `zig/p`, alongside the workload and dual Python oracles.
