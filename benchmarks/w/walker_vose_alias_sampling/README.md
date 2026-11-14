# Walker–Vose alias sampling

This in-progress benchmark builds an alias table for a finite discrete
distribution and replays a supplied tape of uniform column and ticket draws.
It is distinct from `discrete_rejection_sampling`, which may consume a
variable number of proposals, and `weighted_random_sampling`, which selects a
weighted subset without replacement.

## Contract

The `i64_array_bytes_output` input is `[n,q,weights[n],(column,ticket)*q]`.
There are 1–16 categories and 0–32 draws. Weights are integers in 0–100 and
their sum `S` must be positive. Every column is in `0..n-1` and every ticket
is in `0..S-1`. Output consists of the selected category IDs as little-endian
signed 64-bit words. Invalid input returns `-1`; an output buffer that is null
or shorter than the nonempty output returns `-2` without writes. A valid empty
draw tape returns zero, including with a null output buffer.

Initialize scaled masses to `n*weight`. Classify categories below `S` as
small and the rest as large, processing each group as a stack initially
filled in ascending category order. Pop one of each, set the small column's
threshold to its scaled mass and its alias to the large category, then reduce
the large mass by `S-threshold` and return it to the appropriate stack.
Columns left over have threshold `S` and alias themselves. For a draw, use
the column if `ticket < threshold[column]`, otherwise its alias. The exact
integer thresholds avoid floating-point rounding. Independent uniform columns
and tickets yield the requested categorical distribution; supplied tapes make
individual benchmark calls reproducible.

Table construction takes O(n) time and space; q draws take O(q) time, plus
O(q) output space. The maximum valid input has 82 words, maximum output is
256 bytes, and a trailing malformed input can use 83 words.

Method references: Walker's alias method and Vose's linear construction are
described in the [SciPy discrete alias urn documentation](https://docs.scipy.org/doc/scipy/tutorial/stats/sampling_dau.html)
and [Vose's paper citation in Apache Commons RNG](https://commons.apache.org/proper/commons-rng/commons-rng-sampling/xref/org/apache/commons/rng/sampling/distribution/AliasMethodDiscreteSampler.html).
These references are used for algorithm identification; no source code or
prose is copied. Ten language drafts, two references, workload fixtures, and
byte-output runner/verifier wiring are present. The verifier source describes
small exhaustive draw tapes, exact distribution checks, proportional weight
scaling, and maximum-frame checks. Static review remains in progress; nothing
has been executed.

| Language | Draft port |
| --- | --- |
| C | [C](../../../c/w/walker_vose_alias_sampling.c) |
| C3 | [C3](../../../c3/w/walker_vose_alias_sampling.c3) |
| C++ | [C++](../../../cpp/w/walker_vose_alias_sampling.cpp) |
| Elisa | [Elisa](../../../elisa/w/walker_vose_alias_sampling.elisa) |
| Mojo | [Mojo](../../../mojo/w/walker_vose_alias_sampling.mojo) |
| Nim | [Nim](../../../nim/w/walker_vose_alias_sampling.nim) |
| Odin | [Odin](../../../odin/w/walker_vose_alias_sampling.odin) |
| Rust | [Rust](../../../rust/w/walker_vose_alias_sampling.rs) |
| V | [V](../../../v/w/walker_vose_alias_sampling.v) |
| Zig | [Zig](../../../zig/w/walker_vose_alias_sampling.zig) |
