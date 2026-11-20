# Van der Corput sequence

This package returns a contiguous window of one-dimensional radical-inverse
terms as exact rational pairs. For each positive index, write the index in the
selected base and reflect its digits across the radix point. The returned
fraction is intentionally unreduced: its denominator records the full digit
width.

## Contract

- ABI: `int64_t van_der_corput_sequence(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)` (`i64_array_bytes_output`).
- Input is exactly `[base, first_index, count]`. The base is 2 through 16, the
  one-based first index is 1 through 4096, and count is 0 through 128. For a
  nonempty window, `first_index + count - 1` must not exceed 4096. The parser
  accepts up to four words so a single trailing word is rejected explicitly.
- Each term is emitted as `[numerator, denominator]`, two little-endian signed
  64-bit integers. If the base-`b` expansion of index `n` has digits
  `d_(L-1)...d_1 d_0`, then `numerator` is the integer whose base-`b` digits are
  `d_0 d_1 ... d_(L-1)` (including leading zeroes in that reversed width), and
  `denominator = b^L`. Thus the output is exactly
  `sum(d_k * b^(-k-1))`, without floating-point arithmetic or fraction
  reduction.
- A zero-length window returns 0 and writes no bytes. A non-null output pointer
  is required even for that empty result. Otherwise the return value is the
  number of bytes written, at most 2048. Invalid or null input returns `-1`;
  null output or insufficient capacity returns `-2` without writes. Input
  validation precedes output validation.
- With the index cap, every numerator and denominator is at most 65536 and
  fits signed 64-bit storage.

## Relationship to existing sequence benchmarks

This is distinct from [`van_ecks_sequence`](../../v/van_ecks_sequence/README.md):
Van der Corput reverses positional digits to produce rational points in the
unit interval, while Van Eck's sequence follows a last-occurrence distance
recurrence over integers.

## Workload and references

[`workload.json`](workload.json) covers multiple bases, a short binary prefix,
zero count, the maximum supported index, malformed frames, invalid bounds,
null buffers, and insufficient capacity. The primary reference builds the
reversed numerator and base-power denominator directly. The independent
reference sums exact `Fraction` contributions from the base digits, then
restores the unreduced denominator required by the contract.

The [University of South Carolina reference](https://people.math.sc.edu/Burkardt/f_src/van_der_corput/van_der_corput.html)
defines the term by writing the index in base `b` and reflecting its digits
about the radix point. The [RosettaGit public task-title index](https://rosettagit.org/tasks/)
was used only to discover the title “Van der Corput sequence.” No task
statement, examples, tests, submissions, or code were used.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/v/van_der_corput_sequence.c`](../../../c/v/van_der_corput_sequence.c) |
| C3 | [`c3/v/van_der_corput_sequence.c3`](../../../c3/v/van_der_corput_sequence.c3) |
| C++ | [`cpp/v/van_der_corput_sequence.cpp`](../../../cpp/v/van_der_corput_sequence.cpp) |
| Elisa | [`elisa/v/van_der_corput_sequence.elisa`](../../../elisa/v/van_der_corput_sequence.elisa) |
| Mojo | [`mojo/v/van_der_corput_sequence.mojo`](../../../mojo/v/van_der_corput_sequence.mojo) |
| Nim | [`nim/v/van_der_corput_sequence.nim`](../../../nim/v/van_der_corput_sequence.nim) |
| Odin | [`odin/v/van_der_corput_sequence.odin`](../../../odin/v/van_der_corput_sequence.odin) |
| Rust | [`rust/v/van_der_corput_sequence.rs`](../../../rust/v/van_der_corput_sequence.rs) |
| V | [`v/v/van_der_corput_sequence.v`](../../../v/v/van_der_corput_sequence.v) |
| Zig | [`zig/v/van_der_corput_sequence.zig`](../../../zig/v/van_der_corput_sequence.zig) |
