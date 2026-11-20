# Bounded Goodstein sequence prefix

Emit a finite prefix of the classical Goodstein sequence for a very small
starting value. This package measures hereditary-base expansion, recursive
base substitution, exact evaluation, and the decrement transition. It does not
claim to compute complete Goodstein sequences or to establish their
termination.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `goodstein_sequence_bounded_prefix`.
- Input is exactly `[start, max_transitions]`, with `start` in `0..=4` and
  `max_transitions` in `0..=16`.
- The initial term uses base 2. For each positive term, recursively express
  every exponent in hereditary base `b`, replace each occurrence of base symbol
  `b` by `b+1`, evaluate the resulting expression, subtract one, and advance
  the base. This definition is the standard Goodstein transition.
- Output is a sequence of little-endian signed-i64 words: `[term_count,
  term_0, ..., term_(term_count-1)]`. It includes the initial value and stops
  immediately after zero or after the requested transition cap.
- Invalid/null input returns `-1`. Null or insufficient output returns `-2`
  with no writes; validation precedes capacity checking.
- Maximum output is 144 bytes (17 terms plus count), and declared workspace is
  512 bytes, including staged prefix and recursive state.

## Boundedness and algorithm

Starts 0 through 3 remain at most 3. For start 4, the first successor is 26
at base 3; thereafter the hereditary expressions have exponents at most 2 and
the leading coefficient is at most 2. At base `b`, the emitted value is less
than `3*b^2`. The 16-transition cap reaches at most base 18, keeping values and
all powered summands below 972, well within signed 64-bit arithmetic.

The primary reference recursively decomposes each numeric term into base
digits, recursively rebases exponent values, and folds the new powers directly.
The independent reference builds a symbolic hereditary expression tree first,
then evaluates that fixed tree at the raised base. These references use
different representations and evaluation paths.

The method is described in Goodstein's [1944 paper](https://doi.org/10.2307/2268019);
Andrew Marks's [UCLA notes, §5.1](https://www.math.ucla.edu/~marks/notes/set_theory_notes_2.pdf)
state the transition explicitly. The pinned RosettaCodeData [popular-title
index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
is discovery provenance only. See [RIGHTS.md](RIGHTS.md).

The hand-pinned [workload](workload.json) includes the zero fixed point, a
one-to-zero sequence, an eight-step prefix, the maximum transition cap,
malformed input, null output, and short capacity. [INVENTORY.md](INVENTORY.md) and
[inventory.json](inventory.json) enumerate package files and ports.

| Language | Source |
|---|---|
| C | [c/g/goodstein_sequence_bounded_prefix.c](../../../c/g/goodstein_sequence_bounded_prefix.c) |
| C3 | [c3/g/goodstein_sequence_bounded_prefix.c3](../../../c3/g/goodstein_sequence_bounded_prefix.c3) |
| C++ | [cpp/g/goodstein_sequence_bounded_prefix.cpp](../../../cpp/g/goodstein_sequence_bounded_prefix.cpp) |
| Elisa | [elisa/g/goodstein_sequence_bounded_prefix.elisa](../../../elisa/g/goodstein_sequence_bounded_prefix.elisa) |
| Mojo | [mojo/g/goodstein_sequence_bounded_prefix.mojo](../../../mojo/g/goodstein_sequence_bounded_prefix.mojo) |
| Nim | [nim/g/goodstein_sequence_bounded_prefix.nim](../../../nim/g/goodstein_sequence_bounded_prefix.nim) |
| Odin | [odin/g/goodstein_sequence_bounded_prefix.odin](../../../odin/g/goodstein_sequence_bounded_prefix.odin) |
| Rust | [rust/g/goodstein_sequence_bounded_prefix.rs](../../../rust/g/goodstein_sequence_bounded_prefix.rs) |
| V | [v/g/goodstein_sequence_bounded_prefix.v](../../../v/g/goodstein_sequence_bounded_prefix.v) |
| Zig | [zig/g/goodstein_sequence_bounded_prefix.zig](../../../zig/g/goodstein_sequence_bounded_prefix.zig) |

Suite registration uses `i64_array_bytes_output`; the runner and verifier use
separate recursive-numeric and symbolic-expression references. No ports,
tests, or package helpers have been executed.
