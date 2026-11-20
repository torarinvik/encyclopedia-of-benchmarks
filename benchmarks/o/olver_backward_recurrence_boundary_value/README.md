# Olver backward recurrence boundary value

This package profiles the finite, inhomogeneous Olver procedure for a second
order linear difference equation from NIST DLMF §3.6(v), Eqs. 3.6.8–3.6.10.
For each bounded candidate endpoint it advances a homogeneous solution `p_n`
and an auxiliary error sequence `e_n`, applies the DLMF relative cutoff
criterion, and reconstructs a boundary solution from `w_N=0`.

## Contract

Input is a binary64 vector
`[M,Nmax,epsilon,w0,a1..aNmax,b1..bNmax,c1..cNmax,d1..dNmax]`.
`M` and `Nmax` must be exact integers with `1<=M<=8` and `M<=Nmax<=12`.
The four coefficient blocks have length `Nmax`. All values must be finite;
`epsilon` is in `[2^-40,0.5]`, `abs(w0)<=16`, `1/16<=abs(a_n)<=16`, and
`abs(b_n),abs(c_n),abs(d_n)<=16`. Frames have exactly `4+4*Nmax` values, so
the largest valid frame is 52 values and one additional parseable value is
reserved for a trailing-frame rejection.

The primary uses the recurrences

```text
p_0=0, p_1=1
a_n*p_(n+1) - b_n*p_n + c_n*p_(n-1) = 0
e_0=w_0
a_n*e_n = c_n*e_(n-1) - d_n*p_n
r_n = abs(e_n / (p_n*p_(n+1)))
```

It finds the smallest `N` in `M..Nmax` for which
`r_N <= epsilon * min(r_1,...,r_M)`. It then sets `w_N=0` and evaluates
`w_n=(p_n*w_(n+1)+e_n)/p_(n+1)` for `n=N-1,...,0`. The output is
`[N,w_0,...,w_M]`; the generated `w_0` must agree with the supplied `w0`.
The profile fixes binary64 operation order to the displayed recurrence and
criterion; ports must not enable fast-math reassociation.

If a required `a_n` is out of range, the input is malformed (`-1`). If a
`p_n*p_(n+1)` needed for the reference minimum or a candidate ratio is
zero/nonfinite, an intermediate or result becomes nonfinite, or no candidate
satisfies the criterion through `Nmax`, the bounded recurrence returns `-3`
with no output. The primary extends its `p/e` state only through the first
accepted `N`. Malformed input has precedence
over output validation; a valid frame with null/short output returns `-2`
before recurrence work. Successful calls return the number of output values.
Output comparison uses absolute tolerance `1e-9` and relative tolerance
`1e-12`.

The independent reference uses the same specified forward cutoff state, then
solves the selected finite boundary problem as a dense linear system with
pivoted elimination instead of Olver's scalar back-substitution. The package
is a bounded numerical profile; it does not claim convergence beyond the
supplied coefficient range or selected finite endpoint.

## Duplicate decision and provenance

`miller_backward_recurrence_normalization` handles a homogeneous recurrence
with arbitrary terminal trial values and a supplied normalization functional.
This package handles an inhomogeneous equation, computes Olver's auxiliary
error state, chooses its finite endpoint using the relative cutoff, and
reconstructs a boundary solution. The operations and returned data differ.

The mathematical procedure follows [NIST DLMF §3.6(v), Olver's algorithm,
Eqs. 3.6.8–3.6.10](https://dlmf.nist.gov/3.6.v). See [RIGHTS.md](RIGHTS.md)
for provenance and reuse notes. All ports are clean-room implementations.

## Language ports

| Language | Source |
|---|---|
| C | [`c/o/olver_backward_recurrence_boundary_value.c`](../../../c/o/olver_backward_recurrence_boundary_value.c) |
| C3 | [`c3/o/olver_backward_recurrence_boundary_value.c3`](../../../c3/o/olver_backward_recurrence_boundary_value.c3) |
| C++ | [`cpp/o/olver_backward_recurrence_boundary_value.cpp`](../../../cpp/o/olver_backward_recurrence_boundary_value.cpp) |
| Elisa | [`elisa/o/olver_backward_recurrence_boundary_value.elisa`](../../../elisa/o/olver_backward_recurrence_boundary_value.elisa) |
| Mojo | [`mojo/o/olver_backward_recurrence_boundary_value.mojo`](../../../mojo/o/olver_backward_recurrence_boundary_value.mojo) |
| Nim | [`nim/o/olver_backward_recurrence_boundary_value.nim`](../../../nim/o/olver_backward_recurrence_boundary_value.nim) |
| Odin | [`odin/o/olver_backward_recurrence_boundary_value.odin`](../../../odin/o/olver_backward_recurrence_boundary_value.odin) |
| Rust | [`rust/o/olver_backward_recurrence_boundary_value.rs`](../../../rust/o/olver_backward_recurrence_boundary_value.rs) |
| V | [`v/o/olver_backward_recurrence_boundary_value.v`](../../../v/o/olver_backward_recurrence_boundary_value.v) |
| Zig | [`zig/o/olver_backward_recurrence_boundary_value.zig`](../../../zig/o/olver_backward_recurrence_boundary_value.zig) |

See [workload.json](workload.json), [primary_oracle.py](primary_oracle.py),
[independent_oracle.py](independent_oracle.py), and the static package
[inventory helper](check_inventory.py). No helper or program is run while
drafting.
