# Stieltjes quotient-difference transform

This package converts the coefficients of a formal power series into the
corresponding finite prefix of an S-fraction using the quotient-difference
(Q-D) rhombus recurrence in [NIST DLMF §3.10(ii), Eqs. 3.10.8–3.10.10](https://dlmf.nist.gov/3.10#E8).
All operations are exact in the prime field `F_998244353`. Input is
`[N,c0,...,c_(N-1)]`, where `2<=N<=9` and each coefficient is a canonical
nonzero residue in `[1,998244352]`.

The initial row is `q_1^k=c_(k+1)/c_k`; the boundary values are `e_0^k=0`.
For each required cell the rhombus rule is

`e_j^k=e_(j-1)^(k+1)+q_j^(k+1)-q_j^k`,
`q_(j+1)^k=q_j^(k+1)e_j^(k+1)/e_j^k`,

with arithmetic modulo `998244353`. A zero `e_j^k` used as a divisor makes the
entire input invalid and returns `-1`, before output-capacity handling. The
retained table region is `q_1^k` for `0<=k<N-1`, then for each `j>=1`,
`e_j^k` for `0<=k<=N-2j-1` and `q_(j+1)^k` for `0<=k<=N-2j-2` when those
ranges are nonempty. The output is `[N,a0,...,a_(N-1)]`, where
`a0=c0`, `a_(2j-1)=q_j^0`, and `a_(2j)=e_j^0` whenever that index is below N.
The header and residues are encoded as little-endian signed-i64 words.

The primary fills the Q-D rhombus directly. The independent reference uses
Hankel-minor determinant ratios and checks the same required pivot conditions.
The native primary uses two fixed `5x9` i64 tables (`q` and `e`) for a total
720-byte workspace. The maximum input is 10 valid / 11 parseable words; the
maximum output is 10 words (80 bytes). The primary uses `O(N^2 log p)` time
for `p=998244353` because each Q-D quotient uses a modular inverse, and
`O(1)` auxiliary workspace beyond the two tables. The determinant reference
uses bounded `O(N^2 * 5!)` time and `O(N^2)` cached determinant storage.

This is distinct from the local [`continued_fraction_convergents`](../../c/continued_fraction_convergents/README.md),
which receives continued-fraction coefficients and evaluates their
approximants. Q-D receives power-series coefficients and derives the
S-fraction coefficients. DLMF is used for the algorithm description only;
no source code, prose, examples, or tests are copied.

## Package files

- [`primary_oracle.py`](primary_oracle.py): direct Q-D table.
- [`independent_oracle.py`](independent_oracle.py): Hankel determinant ratios.
- [`workload.json`](workload.json): bounded field, pivot, framing, capacity,
  and ABI fixtures.
- `verify_workload.py` and `check_inventory.py` provide static APIs and have
  not been run.

## Language ports

- [C](../../../c/s/stieltjes_quotient_difference_transform.c)
- [C3](../../../c3/s/stieltjes_quotient_difference_transform.c3)
- [C++](../../../cpp/s/stieltjes_quotient_difference_transform.cpp)
- [Elisa](../../../elisa/s/stieltjes_quotient_difference_transform.elisa)
- [Mojo](../../../mojo/s/stieltjes_quotient_difference_transform.mojo)
- [Nim](../../../nim/s/stieltjes_quotient_difference_transform.nim)
- [Odin](../../../odin/s/stieltjes_quotient_difference_transform.odin)
- [Rust](../../../rust/s/stieltjes_quotient_difference_transform.rs)
- [V](../../../v/s/stieltjes_quotient_difference_transform.v)
- [Zig](../../../zig/s/stieltjes_quotient_difference_transform.zig)
