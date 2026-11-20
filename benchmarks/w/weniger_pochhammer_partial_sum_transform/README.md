# Weniger Pochhammer partial-sum transform

This package evaluates one finite Weniger transform from the [NIST DLMF
§3.9(v), Eqs. 3.9.13 and 3.9.16](https://dlmf.nist.gov/3.9#E16). It fixes
`beta=1`, accepts `n=0..8` and `k=3..4`, and reads
`[n,k,a0,...,a_(n+k+1)]`. Every supplied term is a nonzero integer in
`[-3,3]`; the additional terms after the partial sums provide the remainder
estimates.

For `j=0..k`, the coefficient is
`c[j]=(n+j+1)_(k-1)/(n+k+1)_(k-1)`, where `(x)_r` is the rising factorial.
The result is

`Σ((-1)^j C(k,j) c[j] s_(n+j) / a_(n+j+1)) / Σ((-1)^j C(k,j) c[j] / a_(n+j+1))`,

with `s[q]=Σ(a[i], i=0..q)`. An exactly zero final denominator is invalid
and returns `-1` before output-capacity handling. A valid result is reduced
to `(numerator, positive denominator)` and encoded as two little-endian signed
64-bit integers. Errors write no bytes; null or undersized output returns
`-2`.

The product-cleared primary uses `P=Π_(r=0..k) a_(n+r+1)` and integer weights
`W[j]=(-1)^j C(k,j)(n+j+1)_(k-1) P/a_(n+j+1)`. Its numerator and denominator
are the sums of `W[j]s_(n+j)` and `W[j]`. At the bounds, the largest rising
factorial is `13·14·15=2730`, `|P/a|<=81`, `|W[j]|<=1,326,780`,
`|denominator|<=6,633,900`, and `|numerator|<=258,722,100`; all intermediates
fit signed 64-bit values. The independent reference sums direct exact
`Fraction` coefficients from DLMF. Native time is `O((n+k)k)` with scalar
workspace. The valid input range is 7–16 words, the one-extra-word parseable
limit is 17, and output is at most 16 bytes.

The coefficient profile is distinct from the local Levin transform: orders
`k=1` and `k=2` would reduce to its power coefficient, so this profile accepts
only `k=3` or `k=4`. It is also distinct from Aitken's single-triple Δ²
transform and Wynn's recursive epsilon tableau. DLMF supplies the formula;
no source code, prose, examples, or tests are copied.

## Package files

- [`primary_oracle.py`](primary_oracle.py): product-cleared integer reference.
- [`independent_oracle.py`](independent_oracle.py): direct exact-fraction reference.
- [`workload.json`](workload.json): bounded rational, singularity, framing,
  capacity, and ABI fixtures.
- `verify_workload.py` and `check_inventory.py` provide static review APIs;
  they have not been run.

## Language ports

- [C](../../../c/w/weniger_pochhammer_partial_sum_transform.c)
- [C3](../../../c3/w/weniger_pochhammer_partial_sum_transform.c3)
- [C++](../../../cpp/w/weniger_pochhammer_partial_sum_transform.cpp)
- [Elisa](../../../elisa/w/weniger_pochhammer_partial_sum_transform.elisa)
- [Mojo](../../../mojo/w/weniger_pochhammer_partial_sum_transform.mojo)
- [Nim](../../../nim/w/weniger_pochhammer_partial_sum_transform.nim)
- [Odin](../../../odin/w/weniger_pochhammer_partial_sum_transform.odin)
- [Rust](../../../rust/w/weniger_pochhammer_partial_sum_transform.rs)
- [V](../../../v/w/weniger_pochhammer_partial_sum_transform.v)
- [Zig](../../../zig/w/weniger_pochhammer_partial_sum_transform.zig)
