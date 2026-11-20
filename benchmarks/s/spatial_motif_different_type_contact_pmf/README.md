# Heterotypic spatial-contact null distribution

This profile computes the exact permutation-model null distribution for the
number of `X-Y` contacts between two equal-length interacting sequence
fragments, where `X` and `Y` are distinct residue types. The two directions
(`X` in sequence 1 opposite `Y` in sequence 2, and `Y` opposite `X`) are
counted together. Their contact counts are dependent, so the distribution is
not the single hypergeometric law used by the local
[`spatial_motif_same_type_contact_pmf`](../spatial_motif_same_type_contact_pmf/README.md)
profile.

## Bounded contract

The `i64_array_bytes_output` entry point accepts exactly
`[L,x1,y1,x2,y2]`, with `1 <= L <= 10`, nonnegative counts, and
`x1+y1 <= L`, `x2+y2 <= L`. Here `xj` and `yj` are the counts of types `X`
and `Y` in sequence `j`; remaining residues are “neither.” The order of the
first sequence does not affect this null distribution, so its `X`, `Y`, and
neither positions may be fixed in three consecutive blocks. The second
sequence is uniformly permuted over all distinct arrangements of its fixed
multiset.

Define

```text
M(a,b,c) = a! / (b! c! (a-b-c)!)
```

when `a,b,c >= 0` and `b+c <= a`, and zero otherwise. There are
`M(L,x2,y2)` equally likely second-sequence arrangements. For each total
contact count `m` from zero through `L`, let `j=m-i`; the exact numerator is

```text
N_m = sum_h sum_i sum_k
      M(x1,h,i) * M(y1,j,k)
      * M(L-x1-y1, x2-h-j, y2-i-k)
```

over `0<=h<=x1`, `0<=i<=x1-h`, `0<=j<=y1`, and `0<=k<=y1-j`, retaining
only terms whose three `M` factors are nonzero. The variables count X-X,
X-Y, Y-X, and Y-Y contacts respectively. This is the chapter's
three-category hypergeometric model and marginal over the two directional
heterotypic counts. The expected contact count is also
`(x1*y2 + y1*x2)/L`.

Success returns little-endian signed i64 words
`[L, denominator, N_0, ..., N_L, E_num, E_den]`, where
`denominator=M(L,x2,y2)` and `E_num/E_den` is the exact expectation reduced
to lowest terms. A zero expectation is encoded as `0/1`. The maximum result
contains 15 words (120 bytes); fixed workspace is capped at 1,024 bytes.
Malformed frames or invalid counts return `-1`. A null output or insufficient
capacity returns `-2` without writing, after input validation.

The formula takes `O(L^4)` arithmetic operations and stores `O(L)` PMF
numerators. With `L<=10`, the largest possible number of distinct multiset
arrangements is `M(10,3,3)=4,200`; each multinomial term and each PMF
numerator is bounded by this value. The weighted expectation numerator is at
most `10*4,200=42,000`, so all intermediate and output integers fit signed
i64. The independent enumeration oracle visits at most 4,200 arrangements.

## References and workload

[`workload.json`](workload.json) covers empty contact classes, one-way and
two-way heterotypic contacts, dependent directional contacts, an all-contact
case, the maximum output capacity, and invalid composition/frame cases.
[`primary_oracle.py`](primary_oracle.py) evaluates the chapter's marginal
multinomial formula. [`independent_oracle.py`](independent_oracle.py)
enumerates unique multiset arrangements of sequence 2 and counts contacts
directly, without using the formula.

## Provenance

This profile follows Jackups and Liang's exact internally random
permutation model for distinct residue types. The distribution is separate
from the same-type X-X branch: the two directional contact counts are
dependent and require the chapter's three-category marginal. The chapter
also discusses positional null models, sequence motifs, and whole-dataset
analysis; those are outside this bounded operation.

- Ronald Jackups Jr. and Jie Liang, “Combinatorial Analysis for Sequence and
  Spatial Motif Discovery in Short Sequence Fragments,” *IEEE/ACM
  Transactions on Computational Biology and Bioinformatics* 7(3), 524–536
  (2010), [DOI 10.1109/TCBB.2008.101](https://doi.org/10.1109/TCBB.2008.101),
  §II-B, Eqs. (2) and following marginal.
- Liang and Jackups, “Sequence and Spatial Motif Discovery in Short Sequence
  Fragments,” *Encyclopedia of Algorithms*, Chapter 601,
  [DOI 10.1007/978-1-4939-2864-4_601](https://doi.org/10.1007/978-1-4939-2864-4_601),
  `OEBPS/AChap601.html`.

The published algorithm and equations are used for attribution and
behavioral specification. The ports, fixtures, and references are clean-room
work; no source code, prose, or protected fixtures are reused. No separate
source-code license is asserted.

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/s/spatial_motif_different_type_contact_pmf.c`](../../../c/s/spatial_motif_different_type_contact_pmf.c) |
| C3 | [`c3/s/spatial_motif_different_type_contact_pmf.c3`](../../../c3/s/spatial_motif_different_type_contact_pmf.c3) |
| C++ | [`cpp/s/spatial_motif_different_type_contact_pmf.cpp`](../../../cpp/s/spatial_motif_different_type_contact_pmf.cpp) |
| Elisa | [`elisa/s/spatial_motif_different_type_contact_pmf.elisa`](../../../elisa/s/spatial_motif_different_type_contact_pmf.elisa) |
| Mojo | [`mojo/s/spatial_motif_different_type_contact_pmf.mojo`](../../../mojo/s/spatial_motif_different_type_contact_pmf.mojo) |
| Nim | [`nim/s/spatial_motif_different_type_contact_pmf.nim`](../../../nim/s/spatial_motif_different_type_contact_pmf.nim) |
| Odin | [`odin/s/spatial_motif_different_type_contact_pmf.odin`](../../../odin/s/spatial_motif_different_type_contact_pmf.odin) |
| Rust | [`rust/s/spatial_motif_different_type_contact_pmf.rs`](../../../rust/s/spatial_motif_different_type_contact_pmf.rs) |
| V | [`v/s/spatial_motif_different_type_contact_pmf.v`](../../../v/s/spatial_motif_different_type_contact_pmf.v) |
| Zig | [`zig/s/spatial_motif_different_type_contact_pmf.zig`](../../../zig/s/spatial_motif_different_type_contact_pmf.zig) |

The ten ports, references, workload, and metadata are present, and the shared
`i64_array_bytes_output` suite registration is integrated. No programs, tests,
scripts, checkers, builds, compilers, profilers, or benchmarks were run while
drafting this package.
