# EKG sequence

Generate a bounded prefix of the EKG (electrocardiogram) sequence. The first
two terms are 1 and 2. Each later term is the least positive integer not
already used that has a common factor greater than 1 with the immediately
preceding term.

## Contract

- ABI: `int64_t ekg_sequence(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)` (`i64_array_bytes_output`).
- Input is exactly `[count]`, with `1 <= count <= 8`. The parser accepts at
  most two words so a trailing word is explicitly invalid.
- The sequence is one-based: `1, 2, 4, 6, 3, 9, 12, 8` for the supported
  maximum prefix. Return all requested terms in order as little-endian signed
  64-bit integers. Success returns `8*count` bytes (at most 64).
- For a new term at one-based position `k >= 3`, scan positive candidates in
  ascending order and choose the first unused candidate whose gcd with the
  previous term exceeds 1. Terms need not be increasing: for example, the
  fifth and eighth terms are 3 and 8.
- The search at position `k` stops at `k * previous_term`. This is a complete
  bound: the previous term has a prime factor `p`; among `p, 2p, ..., kp`,
  at most `k-1` values have been used, so at least one eligible unused value
  occurs no later than `kp <= k * previous_term`. Starting with `a(2)=2`,
  induction gives `a(k) <= k!`. With `k<=8`, no candidate exceeds
  `8! = 40,320`; the fixed membership table has 40,321 entries.
- Null input, malformed length, or a count outside `1..8` returns `-1`.
  Input validation and sequence construction precede output validation. A null
  output pointer or capacity below `8*count` returns `-2` without writes.

## Distinction from local sequence profiles

This recurrence is distinct from [`mian_chowla_sequence`](../../m/mian_chowla_sequence/README.md),
which rejects candidates when unordered pair sums collide; [`golombs_sequence`](../../g/golombs_sequence/README.md),
which follows a self-describing run-length recurrence; and [`van_ecks_sequence`](../../v/van_ecks_sequence/README.md),
which emits distances between previous occurrences. EKG selects by a gcd
constraint with the immediately preceding term and a least-unused rule.

## Workload and references

[`workload.json`](workload.json) includes the initial terms, a candidate that
must skip an already-used value, the non-monotone fifth term, the maximum
prefix, malformed inputs, and output-buffer errors. The primary reference
keeps an incrementally marked membership table and uses Euclid's gcd. The
independent reference scans the term list for reuse and factors the preceding
term by trial division to test for a shared factor.

The recurrence is defined in Lagarias, Rains, and Sloane, [“The EKG Sequence”](https://arxiv.org/abs/math/0204011),
and catalogued as [OEIS A064413](https://oeis.org/A064413). The
[RosettaGit task-title index](https://rosettagit.org/tasks/) was used only to
discover the title. No task statements, examples, tests, submissions, or code
were used; all contracts and implementations here are independently authored.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/e/ekg_sequence.c`](../../../c/e/ekg_sequence.c) |
| C3 | [`c3/e/ekg_sequence.c3`](../../../c3/e/ekg_sequence.c3) |
| C++ | [`cpp/e/ekg_sequence.cpp`](../../../cpp/e/ekg_sequence.cpp) |
| Elisa | [`elisa/e/ekg_sequence.elisa`](../../../elisa/e/ekg_sequence.elisa) |
| Mojo | [`mojo/e/ekg_sequence.mojo`](../../../mojo/e/ekg_sequence.mojo) |
| Nim | [`nim/e/ekg_sequence.nim`](../../../nim/e/ekg_sequence.nim) |
| Odin | [`odin/e/ekg_sequence.odin`](../../../odin/e/ekg_sequence.odin) |
| Rust | [`rust/e/ekg_sequence.rs`](../../../rust/e/ekg_sequence.rs) |
| V | [`v/e/ekg_sequence.v`](../../../v/e/ekg_sequence.v) |
| Zig | [`zig/e/ekg_sequence.zig`](../../../zig/e/ekg_sequence.zig) |
