# Minkowski question-mark function on rationals

This benchmark evaluates the exact question-mark value of one bounded rational
number in `[0,1]`. It returns an exact dyadic pair rather than a floating-point
approximation.

## Contract

The exported symbol is `minkowski_question_mark_rational`, using the
`i64_array_bytes_output` ABI. Input is `[p,q]`, where `0<=p<=q` and
`1<=q<=1,000,000`; the fraction need not be reduced. For `0<p<q`, its regular
finite continued fraction is `[0;a1,...,an]` with positive partial quotients
and final quotient `an>=2`. The bounded profile accepts it only when
`a1+...+an<=60`. The endpoints are handled directly.

For an interior rational, the value is
`?([0;a1,...,an]) = sum(j=1..n, (-1)^(j-1) * 2^(1-(a1+...+aj)))`.
If `S=a1+...+an`, the returned exponent is `S-1`; the alternating sum is
scaled to its exact integer numerator using those prefix sums.
The quotient sum cap gives `0<=S<=60`, so no shift exceeds 59. The sum of
absolute term magnitudes in any numerator prefix is less than `2^60`, within
signed i64. Stern-Brocot cross-products are bounded by `1,000,000^2`, and its
dyadic endpoint numerators stay below `2^60`.

The output consists of two little-endian signed 64-bit words
`[numerator, exponent]`, representing `numerator / 2^exponent` in lowest terms.
The exponent is at most 59. Invalid input returns `-1`. Null or short output
returns `-2`, with no output bytes written; input validity is checked first.

## Algorithms and references

The primary reference derives the partial quotients by Euclid's algorithm and
forms the finite alternating dyadic sum. The independent reference locates the
fraction by repeated Stern-Brocot mediants and bisects the endpoint function
values at the same time. These use separate traversals and representations.

Alkauskas gives the continued-fraction definition and states that the sum
terminates for rationals in [“The moments of Minkowski question mark function:
the dyadic period function”](https://doi.org/10.1017/S0017089509990152). A second
description of the mediant construction appears in Wolfram MathWorld's
[Minkowski's Question Mark Function](https://mathworld.wolfram.com/MinkowskisQuestionMarkFunction.html).
The pinned RosettaCodeData score-20 [title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
lists “Minkowski-question-mark-function” and supplied discovery only. This is distinct from the repository's Minkowski
sum and Minkowski distance geometry operations, and from continued-fraction
profiles that serialize coefficients or compute convergents.

The workload pins small exact rationals, the maximum quotient-sum boundary,
nonreduced input, malformed frames, and output errors. See [workload.json](workload.json),
[RIGHTS.md](RIGHTS.md), [INVENTORY.md](INVENTORY.md), and the two Python references.
Static helpers are authored but have not been executed.

## Native ports

| Language | Source |
|---|---|
| C | [`minkowski_question_mark_rational.c`](../../../c/m/minkowski_question_mark_rational.c) |
| C3 | [`minkowski_question_mark_rational.c3`](../../../c3/m/minkowski_question_mark_rational.c3) |
| C++ | [`minkowski_question_mark_rational.cpp`](../../../cpp/m/minkowski_question_mark_rational.cpp) |
| Elisa | [`minkowski_question_mark_rational.elisa`](../../../elisa/m/minkowski_question_mark_rational.elisa) |
| Mojo | [`minkowski_question_mark_rational.mojo`](../../../mojo/m/minkowski_question_mark_rational.mojo) |
| Nim | [`minkowski_question_mark_rational.nim`](../../../nim/m/minkowski_question_mark_rational.nim) |
| Odin | [`minkowski_question_mark_rational.odin`](../../../odin/m/minkowski_question_mark_rational.odin) |
| Rust | [`minkowski_question_mark_rational.rs`](../../../rust/m/minkowski_question_mark_rational.rs) |
| V | [`minkowski_question_mark_rational.v`](../../../v/m/minkowski_question_mark_rational.v) |
| Zig | [`minkowski_question_mark_rational.zig`](../../../zig/m/minkowski_question_mark_rational.zig) |
