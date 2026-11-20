# MRG32k3a combined recursive generator

This package emits a bounded integer trace from L’Ecuyer’s combined MRG32k3a
generator. It exposes the generator's combined integer `z_n`, avoiding a
floating-point normalization step while preserving both component recurrences.

## Contract

The `i64_array_bytes_output` input is exactly
`[x1_oldest,x1_middle,x1_newest,x2_oldest,x2_middle,x2_newest,count]`.
Each three-word component state is ordered `(x_(n-3), x_(n-2), x_(n-1))`.
The first component words must lie in `[0,4294967087)` and its state must not
be all zero. The second component words must lie in `[0,4294944443)` and its
state must not be all zero. `count` is in `[0,64]`.

For each step, update in this order:

1. `x1_next = (1403580*x1_middle - 810728*x1_oldest) mod 4294967087`.
2. `x2_next = (527612*x2_newest - 1370589*x2_oldest) mod 4294944443`.
3. Shift each component's three-word state left and append its new value.
4. Emit `z = (x1_next - x2_next) mod 4294967087` as one little-endian signed
   i64 word.

The modulus operation is normalized to a nonnegative residue. Products and
their differences fit signed 64-bit intermediates throughout the stated
domain. A zero count returns zero bytes after validating the complete state;
it permits a null output. Malformed input returns `-1`. For a positive count,
a null output or capacity below `8*count` returns `-2`. Errors write no bytes.

The valid frame has 7 words; one additional parseable word is reserved to
detect trailing input. Output is at most 512 bytes. The fixed workspace cap is
128 bytes, covering the six-word rolling state, scalar intermediates, and
bounded serialization helper state.
Generation takes `O(count)` time and `O(1)` auxiliary space.

## Distinction and source

The local [`subtractive_prng_bentley_seeded_sequence`](../subtractive_prng_bentley_seeded_sequence/README.md)
uses a single lag-55/lag-24 subtractive recurrence with Bentley initialization.
The local linear congruential generator uses one multiply-add state. Neither
has MRG32k3a's two order-3 component recurrences and modular difference output.

The recurrence and component moduli follow L’Ecuyer’s
[*Good Parameter Sets for Combined Multiple Recursive Random Number Generators*](https://www.iro.umontreal.ca/~lecuyer/myftp/papers/opres-combmrg2-1999.pdf)
and the explicit MRG32k3a description in
[*An Object-Oriented Random-Number Package with Many Long Streams and Substreams*](https://www.iro.umontreal.ca/~lecuyer/myftp/papers/streams00s.pdf), §1.1.
The [pinned RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used for title discovery only. This profile accepts an explicit state and
does not implement seed expansion, floating uniform conversion, streams, or
skip-ahead matrices. All contract wording, source code, references, and
fixtures here are original; see [RIGHTS.md](RIGHTS.md).

## References and workload

The primary reference rolls two three-word states. The independent reference
stores both generated component histories and selects their aligned suffix.
The [workload](workload.json) includes zero-, one-, and two-step traces, a
64-word maximum output, state/count validation, null framing, and capacity
boundaries. The package-local static helper compares both references against
each pinned fixture; it has not been run.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/m/mrg32k3a_combined_recursive_generator.c`](../../../c/m/mrg32k3a_combined_recursive_generator.c) |
| C3 | [`c3/m/mrg32k3a_combined_recursive_generator.c3`](../../../c3/m/mrg32k3a_combined_recursive_generator.c3) |
| C++ | [`cpp/m/mrg32k3a_combined_recursive_generator.cpp`](../../../cpp/m/mrg32k3a_combined_recursive_generator.cpp) |
| Elisa | [`elisa/m/mrg32k3a_combined_recursive_generator.elisa`](../../../elisa/m/mrg32k3a_combined_recursive_generator.elisa) |
| Mojo | [`mojo/m/mrg32k3a_combined_recursive_generator.mojo`](../../../mojo/m/mrg32k3a_combined_recursive_generator.mojo) |
| Nim | [`nim/m/mrg32k3a_combined_recursive_generator.nim`](../../../nim/m/mrg32k3a_combined_recursive_generator.nim) |
| Odin | [`odin/m/mrg32k3a_combined_recursive_generator.odin`](../../../odin/m/mrg32k3a_combined_recursive_generator.odin) |
| Rust | [`rust/m/mrg32k3a_combined_recursive_generator.rs`](../../../rust/m/mrg32k3a_combined_recursive_generator.rs) |
| V | [`v/m/mrg32k3a_combined_recursive_generator.v`](../../../v/m/mrg32k3a_combined_recursive_generator.v) |
| Zig | [`zig/m/mrg32k3a_combined_recursive_generator.zig`](../../../zig/m/mrg32k3a_combined_recursive_generator.zig) |
