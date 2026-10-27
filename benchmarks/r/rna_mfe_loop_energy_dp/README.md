# RNA minimum free-energy loop DP

This profile implements the chapter's minimum-free-energy recurrence in
“RNA Secondary Structure Prediction by Minimum Free Energy,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_347`](https://doi.org/10.1007/978-1-4939-2864-4_347).
It uses the chapter's `V[i,j]` loop recurrence and `W[i]` prefix recurrence,
with an explicitly supplied bounded loop-energy table.

Input is `[n,bases[n],loop_costs[6][13][3]]`. Bases are encoded `A=0,C=1,
G=2,U=3`, `4<=n<=12`, and the table stores signed integer energies in
`[-1000,1000]`. Pair types are ordered `AU,UA,CG,GC,GU,UG`; table indexing is
pair type, then accessible unpaired-base count `0..12`, then direct child-pair
count `0..2`. A pair is allowed only for those six canonical/wobble types and
when `j-i>=4`, matching the chapter's minimum hairpin separation. In this
bounded domain a loop cannot have three direct child pairs.

For each closing pair the DP minimizes the supplied loop energy plus the
minimum energies of its direct child pairs. `W` then chooses among leaving the
last base unpaired or closing a pair there. Equal-energy structures are
resolved by lexicographically smallest ordered list of `(i,j)` pairs. This tie
rule and the finite integer table are profile refinements; the table is the
complete scoring input, not a claim about experimentally calibrated nearest-
neighbor parameters.

Output is `[minimum_energy,pair_count,(i,j)*pair_count]` as little-endian
signed i64 values. The primary oracle uses the `V/W` interval recurrence; the
independent verifier enumerates all noncrossing structures and scores their
direct-child loops. The objective is minimum loop energy, distinct from
Nussinov's maximum-pair-count objective. The package does not implement
pseudoknots or a specific thermodynamic parameter set.

Malformed input returns `-1`; null output or insufficient capacity returns
`-2` without writing. Maximum input length is 247 i64 values, maximum output
is 112 bytes, and declared workspace is 16384 bytes.

| Language | Port |
|---|---|
| C | `c/r/rna_mfe_loop_energy_dp.c` |
| C3 | `c3/r/rna_mfe_loop_energy_dp.c3` |
| C++ | `cpp/r/rna_mfe_loop_energy_dp.cpp` |
| Elisa | `elisa/r/rna_mfe_loop_energy_dp.elisa` |
| Nim | `nim/r/rna_mfe_loop_energy_dp.nim` |
| Odin | `odin/r/rna_mfe_loop_energy_dp.odin` |
| Rust | `rust/r/rna_mfe_loop_energy_dp.rs` |
| V | `v/r/rna_mfe_loop_energy_dp.v` |
| Zig | `zig/r/rna_mfe_loop_energy_dp.zig` |
