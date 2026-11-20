# Multidimensional Newton-Raphson

This benchmark performs a bounded number of coupled Newton updates for a
two-variable nonlinear system. Each update constructs the system Jacobian,
solves its 2-by-2 correction equations, and changes both coordinates.

## Contract

The exported symbol is `multidimensional_newton_raphson`, using the
`i64_array_bytes_output` ABI. Input is exactly `[x0_milli,y0_milli,updates]`.
Both coordinate words must be in `900..1500`, representing starting values in
`[0.9,1.5]`; the update count must be in `1..8`.

The system is

```text
F1(x,y) = x*x + y - 3
F2(x,y) = x + y*y - 3
```

For each requested update, evaluate `F1` and `F2`, solve
`[[2*x,1],[1,2*y]] * [dx,dy] = [F1,F2]`, and set
`(x,y) = (x-dx,y-dy)`. The arithmetic is binary64 and exactly the requested
number of steps is performed; no convergence stopping rule is used.

Output is `[round_1e9(x),round_1e9(y)]` as two little-endian signed i64 words,
with ties rounded away from zero. Success returns 16. Malformed or
out-of-domain input returns `-1`; null output or capacity below 16 returns
`-2`. Input validity is checked before output validity, and errors leave the
output untouched. Maximum valid input length is 3 and maximum parseable length
is 4. Native scratch is at most 128 bytes, excluding caller-owned input and
output buffers.

## Complexity

For `u` requested updates, time is `O(u)` and scratch space is `O(1)`; the
2-by-2 Jacobian solve has fixed size.

## Method and references

The primary reference applies the binary64 closed-form inverse of the 2-by-2
Jacobian. The independent reference performs the same binary64 updates but
forms the four Jacobian entries and uses Cramer's rule, giving the solve a
separate operation path. Both references round after the final update, with
ties away from zero. The bounded start region keeps the Jacobian determinant
nonzero through the specified updates.

Chen and Strader's paper, [“A normalized multidimensional Newton-Raphson
method”](https://ntrs.nasa.gov/api/citations/19780021877/downloads/19780021877.pdf),
describes the general simultaneous-equation Newton step in section 2. This
benchmark uses the standard coupled Jacobian step described above. It does not
implement or claim to measure the paper's separate normalization transforms.
The local [`newton_raphson_method`](../newton_raphson_method/README.md) profile
is one-dimensional, and Gaussian elimination profiles benchmark a general
linear-system solve rather than this nonlinear update loop.

## Native ports

| Language | Source |
|---|---|
| C | [`multidimensional_newton_raphson.c`](../../../c/m/multidimensional_newton_raphson.c) |
| C3 | [`multidimensional_newton_raphson.c3`](../../../c3/m/multidimensional_newton_raphson.c3) |
| C++ | [`multidimensional_newton_raphson.cpp`](../../../cpp/m/multidimensional_newton_raphson.cpp) |
| Elisa | [`multidimensional_newton_raphson.elisa`](../../../elisa/m/multidimensional_newton_raphson.elisa) |
| Mojo | [`multidimensional_newton_raphson.mojo`](../../../mojo/m/multidimensional_newton_raphson.mojo) |
| Nim | [`multidimensional_newton_raphson.nim`](../../../nim/m/multidimensional_newton_raphson.nim) |
| Odin | [`multidimensional_newton_raphson.odin`](../../../odin/m/multidimensional_newton_raphson.odin) |
| Rust | [`multidimensional_newton_raphson.rs`](../../../rust/m/multidimensional_newton_raphson.rs) |
| V | [`multidimensional_newton_raphson.v`](../../../v/m/multidimensional_newton_raphson.v) |
| Zig | [`multidimensional_newton_raphson.zig`](../../../zig/m/multidimensional_newton_raphson.zig) |

The workload includes symmetric, asymmetric, one-update, and eight-update
cases, as well as input-bound and output-buffer errors. See
[workload.json](workload.json), [RIGHTS.md](RIGHTS.md), and
[INVENTORY.md](INVENTORY.md). Static reference reconciliation and inventory
helpers are included but have not been executed.
