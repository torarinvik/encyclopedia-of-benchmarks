# Modified Newton method for a multiple root

This benchmark applies the Newton correction multiplied by a known root
multiplicity. It uses `f(x)=(x-1)^2(x+2)`, whose double root is `x=1` and
whose derivative is `f'(x)=3(x-1)(x+1)`. Each update is

```text
x <- x - 2*f(x)/f'(x)
```

The `float64_pair` input is `[initial_x, iteration_count]`, with
`1<=initial_x<=2` and an integer update count from 0 through 8. Invalid inputs
return `-1.0`. An iterate that reaches the exact root remains fixed; this
handles the zero derivative at that multiple root. The primary reference uses
binary64 arithmetic and the independent reference uses a 90-digit Decimal
recurrence.

The method is distinct from ordinary Newton iteration, which uses the
uncorrected `f/f'` step, and from Halley's second-derivative update. It also
differs from Aitken's Δ² sequence transform: the modified Newton step generates
the next root iterate using the known multiplicity parameter.
The native recurrence takes `O(iteration_count)` time and `O(1)` auxiliary
space.

NIST DLMF describes the correction in [§3.8(ii), Newton's rule](https://dlmf.nist.gov/3.8#E4).
This package uses the mathematical method only; the fixed polynomial profile,
bounded contract, ports, and workload are clean-room work. See
[`RIGHTS.md`](RIGHTS.md).

The workload covers zero, one, two, and eight updates, two starting points,
the exact root, and invalid range and iteration controls. Package metadata and
static inventory are in this directory.

| Language | Port |
|---|---|
| C | [`c/m/modified_newton_multiple_root.c`](../../../c/m/modified_newton_multiple_root.c) |
| C3 | [`c3/m/modified_newton_multiple_root.c3`](../../../c3/m/modified_newton_multiple_root.c3) |
| C++ | [`cpp/m/modified_newton_multiple_root.cpp`](../../../cpp/m/modified_newton_multiple_root.cpp) |
| Elisa | [`elisa/m/modified_newton_multiple_root.elisa`](../../../elisa/m/modified_newton_multiple_root.elisa) |
| Mojo | [`mojo/m/modified_newton_multiple_root.mojo`](../../../mojo/m/modified_newton_multiple_root.mojo) |
| Nim | [`nim/m/modified_newton_multiple_root.nim`](../../../nim/m/modified_newton_multiple_root.nim) |
| Odin | [`odin/m/modified_newton_multiple_root.odin`](../../../odin/m/modified_newton_multiple_root.odin) |
| Rust | [`rust/m/modified_newton_multiple_root.rs`](../../../rust/m/modified_newton_multiple_root.rs) |
| V | [`v/m/modified_newton_multiple_root.v`](../../../v/m/modified_newton_multiple_root.v) |
| Zig | [`zig/m/modified_newton_multiple_root.zig`](../../../zig/m/modified_newton_multiple_root.zig) |
