# Hickerson almost-integer expression

Evaluate the floating-point expression

\[
h_n=\frac{n!}{2(\ln 2)^{n+1}}
\]

for a bounded positive integer `n`. Its values through `n=15` have a decimal
fractional first digit of 0 or 9, while values for `n=16,17` do not. The
benchmark returns the binary64 approximation itself; it does not classify the
result or substitute its nearby integer. That distinction keeps the measured
result separate from the exact ordered Bell number.

## Contract

The `i64_array_float64` input is exactly `[n]`, with `1<=n<=17`. The output is
the binary64 value `h_n`. A null input, wrong frame, or out-of-range value
returns `-1e300`. The valid profile is small enough that all values are finite
in binary64. Workload comparisons use absolute tolerance `6e-6` and relative
tolerance `1e-12`; the published MathWorld values are shown to five decimal
places, while the independent reference uses 100-digit decimal arithmetic.

The ten ports use the algebraically equivalent recurrence
`h_1=1/(2*ln(2)^2)` and `h_n=(n/ln(2))*h_(n-1)`. The primary oracle uses the
same recurrence. The independent oracle evaluates `n!/(2*ln(2)^(n+1))`
directly with Python `Decimal` precision. This benchmark measures the
Hickerson expression, not the exact ordered Bell sequence: the nearest
integers agree with ordered Bell numbers only over the range documented by
OEIS A034172, and the real-valued outputs are not those integers.

## Provenance

The [RosettaGit title index](https://rosettagit.org/tasks/) was used only to
discover the title “Hickerson series of almost integers.” No task statement,
examples, tests, submissions, or code were used. The mathematical expression
and near-integer behavior come from Wolfram MathWorld's [Almost Integer
entry](https://mathworld.wolfram.com/AlmostInteger.html). [OEIS
A034172](https://oeis.org/A034172) records the nearest integers and cites
H. S. Wilf, [*Generatingfunctionology*](https://www2.math.upenn.edu/~wilf/gfology2.pdf).

## Workload and inventory

[`workload.json`](workload.json) contains all supported indices and malformed
boundary cases. Primary and independent references are in
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The static file/link review
helper is [`check_inventory.py`](check_inventory.py); it has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/h/hickerson_almost_integer.c`](../../../c/h/hickerson_almost_integer.c) |
| C3 | [`c3/h/hickerson_almost_integer.c3`](../../../c3/h/hickerson_almost_integer.c3) |
| C++ | [`cpp/h/hickerson_almost_integer.cpp`](../../../cpp/h/hickerson_almost_integer.cpp) |
| Elisa | [`elisa/h/hickerson_almost_integer.elisa`](../../../elisa/h/hickerson_almost_integer.elisa) |
| Mojo | [`mojo/h/hickerson_almost_integer.mojo`](../../../mojo/h/hickerson_almost_integer.mojo) |
| Nim | [`nim/h/hickerson_almost_integer.nim`](../../../nim/h/hickerson_almost_integer.nim) |
| Odin | [`odin/h/hickerson_almost_integer.odin`](../../../odin/h/hickerson_almost_integer.odin) |
| Rust | [`rust/h/hickerson_almost_integer.rs`](../../../rust/h/hickerson_almost_integer.rs) |
| V | [`v/h/hickerson_almost_integer.v`](../../../v/h/hickerson_almost_integer.v) |
| Zig | [`zig/h/hickerson_almost_integer.zig`](../../../zig/h/hickerson_almost_integer.zig) |
