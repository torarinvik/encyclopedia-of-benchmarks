# Same-type spatial-contact null distribution

This profile computes the chapter's permutation-model null distribution for
the number of same-type (`X-X`) contacts between two equal-length sequence
fragments. If `x1` and `x2` are the counts of residue `X` in the two fragments
of length `l`, then the chapter gives

```text
Pr[F=i] = C(x1,i) C(l-x1,x2-i) / C(l,x2)
E[F]    = x1*x2/l
```

The input is `[length, first_X_count, second_X_count]` as signed i64 words.
The bounded domain is `1 <= length <= 16` and each count is in `[0,length]`.
The implementation returns the exact integer numerators for the complete
support, a common denominator, and the reduced expected value as a rational.

Output is little-endian signed i64:

```text
[minimum_contact_count, maximum_contact_count, pmf_denominator,
  numerator_at_minimum, ..., numerator_at_maximum,
  reduced_expectation_numerator, reduced_expectation_denominator]
```

The support is `[max(0,x1+x2-l), min(x1,x2)]`. Since `l<=16`, all binomial
coefficients and products fit signed 64-bit words; the maximum output is 112
bytes and fixed workspace is 4096 bytes. Invalid input returns `-1`; null
output or insufficient capacity returns `-2` without writing.

This is a precise partial profile of DOI 601's same-type spatial-contact
permutation null model. It does not implement mixed-type dependent contact
significance, positional null models, sequence motifs, multiple-sequence
dataset analysis, or the broader protein motif-discovery pipeline.

Source: Jie Liang and Ronald Jackups, “Sequence and Spatial Motif Discovery in
Short Sequence Fragments,” Encyclopedia of Algorithms, DOI
`10.1007/978-1-4939-2864-4_601`, `OEBPS/AChap601.html`, “Expectation for
Interacting Residues of the Same Type.” No source-code license is asserted;
the ports are clean-room implementations of the displayed distribution.

Primary and independent verifier oracles:
`benchmarks/spatial_motif_same_type_contact_pmf_oracle.py` and
`benchmarks/spatial_motif_same_type_contact_pmf_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/s/spatial_motif_same_type_contact_pmf.c` |
| C3 | `c3/s/spatial_motif_same_type_contact_pmf.c3` |
| C++ | `cpp/s/spatial_motif_same_type_contact_pmf.cpp` |
| Elisa | `elisa/s/spatial_motif_same_type_contact_pmf.elisa` |
| Nim | `nim/s/spatial_motif_same_type_contact_pmf.nim` |
| Odin | `odin/s/spatial_motif_same_type_contact_pmf.odin` |
| Rust | `rust/s/spatial_motif_same_type_contact_pmf.rs` |
| V | `v/s/spatial_motif_same_type_contact_pmf.v` |
| Zig | `zig/s/spatial_motif_same_type_contact_pmf.zig` |
