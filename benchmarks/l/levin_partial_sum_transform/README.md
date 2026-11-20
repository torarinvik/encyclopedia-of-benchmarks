# Levin partial-sum transform

This package computes one finite Levin transform from DLMF §3.9(v),
Eqs. 3.9.13–3.9.14, at the caller-selected partial-sum index `n` and order
`k`. It accepts `[n,k,a₀,…,a_(n+k+1)]`, with `0<=n<=8`, `1<=k<=3`, and all
terms nonzero integers in `[-3,3]`. The extra term after each selected partial
sum supplies the remainder estimate used by Levin's formula.

For `j=0..k`, the implementation uses

`c[j] = ((n+j+1)/(n+k+1))^(k-1)`

and returns

`Σ((-1)^j C(k,j) c[j] s_(n+j) / a_(n+j+1)) / Σ((-1)^j C(k,j) c[j] / a_(n+j+1))`,

where `s[q]=Σ(a[i], i=0..q)`. A zero final denominator makes the input
undefined for this profile and returns `-1`; it is checked before output
capacity. Any supplied zero term is rejected because the selected remainder
estimate divides by each of `a_(n+1)..a_(n+k+1)`. Valid results are reduced
to a canonical `(numerator, positive denominator)` pair and encoded as two
little-endian signed 64-bit integers. Errors write no bytes; insufficient or
null output returns `-2`.

The primary clears the term denominators with their product, turning the
formula into bounded integer weight and sum accumulations. With `n<=8`,
`k<=3`, and terms bounded by 3, each weight is at most 11,664 in magnitude,
the transformed numerator is at most 1,679,616, and all native intermediates
fit signed 64-bit values. The independent reference uses direct exact
`Fraction` coefficients from the displayed DLMF expression. Both references
and the workload pin exact zero-denominator behavior. Native work is
`O((n+k)k)` time with scalar workspace; the maximum input is 15 words and the
maximum output is 16 bytes.

This is distinct from the local Aitken Δ² transform, Euler's alternating
series forward-difference transform, and Wynn's epsilon/Shanks tableau:
Levin's profile explicitly weights partial sums by supplied next-term
remainder estimates. DLMF is used for the mathematical description only.
No code, prose, examples, or tests are copied.

## References and workload

- [`primary_oracle.py`](primary_oracle.py): product-cleared integer sums.
- [`independent_oracle.py`](independent_oracle.py): direct exact-fraction formula.
- [`workload.json`](workload.json): order-one through order-three, signed terms,
  exact singularity, maximum-frame success, malformed frame, and ABI cases.
- `verify_workload.py` and `check_inventory.py` are static helpers and were not run.

## Language ports

- [C](../../../c/l/levin_partial_sum_transform.c)
- [C3](../../../c3/l/levin_partial_sum_transform.c3)
- [C++](../../../cpp/l/levin_partial_sum_transform.cpp)
- [Elisa](../../../elisa/l/levin_partial_sum_transform.elisa)
- [Mojo](../../../mojo/l/levin_partial_sum_transform.mojo)
- [Nim](../../../nim/l/levin_partial_sum_transform.nim)
- [Odin](../../../odin/l/levin_partial_sum_transform.odin)
- [Rust](../../../rust/l/levin_partial_sum_transform.rs)
- [V](../../../v/l/levin_partial_sum_transform.v)
- [Zig](../../../zig/l/levin_partial_sum_transform.zig)
