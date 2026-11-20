# Aitken delta-squared sequence transform

Apply Aitken's Δ² transformation independently to each consecutive triple
in a bounded integer sequence. The package keeps the result exact by writing
each transformed value as a reduced rational numerator/denominator pair.

## Contract

The `i64_array_bytes_output` input is `[n, s0, s1, ..., s(n-1)]`, with
`2 <= n <= 64`, exactly `n + 1` words, and each sequence value in
`[-1,000,000, 1,000,000]`. Each adjacent triple emits

`(s0*s2 - s1*s1) / (s0 - 2*s1 + s2)`.

Each pair is reduced by its greatest common divisor and has a positive
denominator. If the second difference is zero and all three values are equal,
the transform is that constant as `(s0, 1)`. If the second difference is zero
for a nonconstant arithmetic triple, the transform is undefined and is
encoded as `(0, 0)`. The output is the consecutive pairs encoded as
little-endian signed 64-bit words. For `n = 2`, the valid result is an empty
byte string.

Malformed input returns `-1`. A null output buffer or insufficient capacity
returns `-2`. Errors write no bytes. Validation precedes output writes.

The bounds keep each numerator within signed 64-bit range: products are at
most `10^12`, their difference is at most `2*10^12`, and the second difference
is at most `4*10^6`. The native ports use constant auxiliary space and take
`O(n)` time; the largest result is 992 bytes for 64 terms.

## Algorithm and distinction

The transformation consumes three consecutive sequence values and removes a
linear error component when the sequence has a nonzero second difference.
This is a sequence extrapolation operation, distinct from the repository's
fixed-point/root-finding routines, which generate iterates from a supplied
function, and from compensated summation, which accumulates values while
tracking roundoff. This package applies the transform to a supplied sequence;
it does not generate the sequence or iterate the transformation.

The operational formula follows NIST's [Digital Library of Mathematical
Functions, §3.9(iii), Aitken's Δ²-process](https://dlmf.nist.gov/3.9#E7).
The integer/rational input profile, zero-denominator convention, and output
encoding are bounded benchmark choices. No source code, prose, examples, or
tests are copied.

## Workload and references

[`workload.json`](workload.json) covers the empty transform, a geometric
triple, exact nonintegral rational results, constant triples, undefined
arithmetic triples, negative denominators, malformed frames, null pointers,
and output capacity. The primary oracle exports `MAX_PARSEABLE_INPUT_LENGTH`,
`MAX_OUTPUT_BYTES`, and `WORKSPACE_BYTES` as the package's 66-word parseable
input, 992-byte output, and zero-byte auxiliary-workspace bounds.
[`primary_oracle.py`](primary_oracle.py) evaluates the reduced
numerator/denominator form directly. [`independent_oracle.py`](independent_oracle.py)
uses exact fractions and the difference quotient form. The package-local
`verify_workload.py` and `check_inventory.py` are static helpers and were not
run.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/a/aitken_delta_squared_sequence_transform.c`](../../../c/a/aitken_delta_squared_sequence_transform.c) |
| C3 | [`c3/a/aitken_delta_squared_sequence_transform.c3`](../../../c3/a/aitken_delta_squared_sequence_transform.c3) |
| C++ | [`cpp/a/aitken_delta_squared_sequence_transform.cpp`](../../../cpp/a/aitken_delta_squared_sequence_transform.cpp) |
| Elisa | [`elisa/a/aitken_delta_squared_sequence_transform.elisa`](../../../elisa/a/aitken_delta_squared_sequence_transform.elisa) |
| Mojo | [`mojo/a/aitken_delta_squared_sequence_transform.mojo`](../../../mojo/a/aitken_delta_squared_sequence_transform.mojo) |
| Nim | [`nim/a/aitken_delta_squared_sequence_transform.nim`](../../../nim/a/aitken_delta_squared_sequence_transform.nim) |
| Odin | [`odin/a/aitken_delta_squared_sequence_transform.odin`](../../../odin/a/aitken_delta_squared_sequence_transform.odin) |
| Rust | [`rust/a/aitken_delta_squared_sequence_transform.rs`](../../../rust/a/aitken_delta_squared_sequence_transform.rs) |
| V | [`v/a/aitken_delta_squared_sequence_transform.v`](../../../v/a/aitken_delta_squared_sequence_transform.v) |
| Zig | [`zig/a/aitken_delta_squared_sequence_transform.zig`](../../../zig/a/aitken_delta_squared_sequence_transform.zig) |

The byte-output runner/verifier and catalog register this profile. The package
and integration received a static source review only; no programs, tests,
scripts, checkers, builds, compilers, profilers, or benchmarks were run.
