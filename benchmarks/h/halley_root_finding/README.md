# Halley root finding

This benchmark replays Halley's second-derivative root iteration on the fixed
polynomial `f(x)=x^3-2`. It returns the iterate after an exact number of
updates, including the initial value when the count is zero.

The `float64_pair` input is `[initial_x, iteration_count]`. `initial_x` must be
finite and in `[0.5,2]`; `iteration_count` must be an integer-valued finite
binary64 number in `[0,8]`. Invalid inputs return `-1.0`.

For each update, the ports evaluate `f`, `f'`, and `f''` and apply

```text
x <- x - 2*f(x)*f'(x) / (2*f'(x)^2 - f(x)*f''(x))
```

The bounded positive interval keeps the denominator nonzero for this cubic.
The primary reference uses binary64 arithmetic; the independent reference
uses 90-digit Decimal arithmetic. Both return one binary64 result. The native
work is `O(k)` time and `O(1)` auxiliary space for `k` requested updates.

This is distinct from Newton's first-derivative update and from Ridders'
bracketed midpoint/interpolation method. It also has a different input and
state from the Aitken sequence transform, which consumes supplied sequence
triples rather than iterating a root function.

## Provenance

NIST DLMF documents Halley's rule in [§3.8(v), Eq. 3.8.12](https://dlmf.nist.gov/3.8#E12),
including its cubic local convergence. This benchmark specializes that update
to `x^3-2`. The formula is used as an algorithm description only; no source
code, prose, figures, or example values are copied. See [RIGHTS.md](RIGHTS.md).

## Workload and language ports

The workload includes zero, one, two, and maximum update counts, both initial
value boundaries, convergence to the cube root of two, and malformed numeric
controls. The references and static package inventory are in this directory.

| Language | Port |
|---|---|
| C | [`c/h/halley_root_finding.c`](../../../c/h/halley_root_finding.c) |
| C3 | [`c3/h/halley_root_finding.c3`](../../../c3/h/halley_root_finding.c3) |
| C++ | [`cpp/h/halley_root_finding.cpp`](../../../cpp/h/halley_root_finding.cpp) |
| Elisa | [`elisa/h/halley_root_finding.elisa`](../../../elisa/h/halley_root_finding.elisa) |
| Mojo | [`mojo/h/halley_root_finding.mojo`](../../../mojo/h/halley_root_finding.mojo) |
| Nim | [`nim/h/halley_root_finding.nim`](../../../nim/h/halley_root_finding.nim) |
| Odin | [`odin/h/halley_root_finding.odin`](../../../odin/h/halley_root_finding.odin) |
| Rust | [`rust/h/halley_root_finding.rs`](../../../rust/h/halley_root_finding.rs) |
| V | [`v/h/halley_root_finding.v`](../../../v/h/halley_root_finding.v) |
| Zig | [`zig/h/halley_root_finding.zig`](../../../zig/h/halley_root_finding.zig) |
