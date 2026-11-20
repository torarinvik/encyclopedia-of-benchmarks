# Aliquot orbit decomposition

Decompose the orbit of one positive seed under the restricted divisor map.
This differs from [`aliquot_sum`](../aliquot_sum/README.md), which evaluates
one map step, [`sociable_number`](../../s/sociable_number/README.md), which checks
specified cycle lengths two or three, and [`problem95`](../../p/problem95/README.md),
which searches a range for its longest returning cycle. This profile reports
the transient and eventual cycle for one seed, including a transient that
merges into a cycle not containing the seed.

## Contract

The `i64_array_bytes_output` input is `[seed,max_transitions]`, with
`1<=seed<=100000` and `1<=max_transitions<=4096`. At most three input words are
parsed so one trailing word is rejected. The orbit-value ceiling is fixed at
100000. For positive `x`, `s(x)` is the sum of its positive proper divisors;
in particular, `s(1)=0`. Reaching zero after a positive term is termination.

The little-endian signed-i64 output is one of:

- `[1,mu,lambda]` when a positive value repeats, with the seed at index zero.
- `[0,positive_term_count,0]` when the orbit reaches zero.
- `[-2,transitions_completed,next_value]` when the next aliquot value exceeds
  100000.
- `[-3,transitions_completed,current_value]` when the transition cap is reached
  before a repeat or termination.
- `[-1,0,0]` for malformed input.

At every in-cap value, zero/repetition is classified before the step cap. The
orbit may therefore report a repeat or termination reached exactly on its
last permitted transition. An over-cap next value is reported immediately.
Malformed input is rejected before output-buffer validation. A valid input
needs a non-null 24-byte output buffer; otherwise the ABI returns `-2` without
writing.

## Method and references

The primary ports retain first-seen sequence indices and report the first
repeated value as `(mu,lambda)`. The primary Python reference uses a map; the
fixed-size language ports keep values in a sorted bounded table, use binary
search for lookup, and shift entries on insertion. The independent reference
computes each aliquot value from the multiplicative divisor-sum formula and
linearly searches the generated history for a repeat. These different lookup
and divisor-sum methods make the orbit result independently checkable.

- [OEIS Wiki, “Aliquot sequences”](https://oeis.org/wiki/Aliquot_sequences)
  defines the recurrence by iterating sums of proper divisors.
- [MathWorld, “Aliquot Sequence”](https://mathworld.wolfram.com/AliquotSequence.html)
  describes aliquot sequences as iterates of the restricted divisor function.
- [OEIS A044050](https://oeis.org/A044050) documents aliquot trajectories and
  their transient/cycle length behavior.
- [MathWorld, “Divisor Function”](https://mathworld.wolfram.com/DivisorFunction.html)
  gives the multiplicative prime-power formula used by the independent
  factorization reference.
- The [RosettaGit task-title index](https://rosettagit.org/tasks/) was used only
  to discover the title “Aliquot sequence classifications.” No task text,
  examples, tests, submissions, or code are used.

See [RIGHTS.md](RIGHTS.md) for source and rights notes.

## Workload and inventory

[`workload.json`](workload.json) covers a fixed point, an amicable cycle, a
nonzero transient into an amicable cycle, termination at zero, both caps,
malformed frames, and output-buffer errors. The two Python references and
ten language ports are listed in [`INVENTORY.md`](INVENTORY.md). The static
inventory helper is [`check_inventory.py`](check_inventory.py); it has not
been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/a/aliquot_orbit_decomposition.c`](../../../c/a/aliquot_orbit_decomposition.c) |
| C3 | [`c3/a/aliquot_orbit_decomposition.c3`](../../../c3/a/aliquot_orbit_decomposition.c3) |
| C++ | [`cpp/a/aliquot_orbit_decomposition.cpp`](../../../cpp/a/aliquot_orbit_decomposition.cpp) |
| Elisa | [`elisa/a/aliquot_orbit_decomposition.elisa`](../../../elisa/a/aliquot_orbit_decomposition.elisa) |
| Mojo | [`mojo/a/aliquot_orbit_decomposition.mojo`](../../../mojo/a/aliquot_orbit_decomposition.mojo) |
| Nim | [`nim/a/aliquot_orbit_decomposition.nim`](../../../nim/a/aliquot_orbit_decomposition.nim) |
| Odin | [`odin/a/aliquot_orbit_decomposition.odin`](../../../odin/a/aliquot_orbit_decomposition.odin) |
| Rust | [`rust/a/aliquot_orbit_decomposition.rs`](../../../rust/a/aliquot_orbit_decomposition.rs) |
| V | [`v/a/aliquot_orbit_decomposition.v`](../../../v/a/aliquot_orbit_decomposition.v) |
| Zig | [`zig/a/aliquot_orbit_decomposition.zig`](../../../zig/a/aliquot_orbit_decomposition.zig) |
