# Bentley-seeded subtractive pseudorandom sequence

Generate a deterministic stream from an explicit seed using the Bentley
initialization for the lag-55, lag-24 subtractive generator. This profile
measures the seed-state construction, 34-step permutation, 165-value warmup,
and requested output prefix. It has no entropy source or random retry loop.

## Contract

Input is `[seed,count]`, with `0 <= seed < 1,000,000,000` and
`0 <= count <= 64`. Build `s[0]=seed`, `s[1]=1`, then
`s[n]=(s[n-2]-s[n-1]) mod 1,000,000,000` for `2 <= n < 55`. The 55-value
initial ring is `r[i]=s[(34*(i+1)) mod 55]` for `0 <= i < 55`. Starting from
that ring, generate and discard `r[55]` through `r[219]`. The returned values
begin with `r[220]` and follow
`r[n]=(r[n-55]-r[n-24]) mod 1,000,000,000`.

The output contains `count` nonnegative values as little-endian signed-i64
words, without a count prefix. The return value is `8*count`. A malformed
frame, seed, or count returns `-1`. A null output or capacity below the
required number of bytes returns `-2` when `count>0`; errors write nothing.
For `count=0`, the valid call returns zero bytes before constructing state and permits a null output.
The maximum valid/parseable input lengths are 2/3 words, output is capped at
512 bytes, and fixed native workspace is 440 bytes: two 55-element i32 arrays
for the seed sequence and rotating state.

## Distinction

The local [`linear_congruential_generator`](../linear_congruential_generator/README.md)
uses one state with a multiply-add transition. The local [`linqshuffler`](../linqshuffler/README.md)
pins .NET 6's 56-entry compatibility generator, with MBIG/MSEED initialization
and a lag-30 subtractor, but measures stable random-key sorting rather than a
standalone output stream. This package uses Bentley's permuted 55-value seed
state, lag 24, a modulus of one billion, and a fixed warmup. Other randomized
benchmarks consume pseudorandom draws internally and do not expose this
sequence operation.

The Rosetta Code title and high-level recurrence are discovery/specification
references only. The bounded ABI, original seed and workload cases, reference
implementations, and ten ports are independently authored. No task text,
source code, task examples, or tests are copied.

## Workload and references

[`workload.json`](workload.json) covers a fresh short stream, the zero-length
boundary, the maximum output length, malformed frames and values, null output,
and insufficient capacity. Successful nonempty fixture bytes are derived by
both package references in the static workload helper; the workload pins the
output length without embedding a published task sequence. The primary uses
a fixed ring buffer. The structurally independent reference materializes the
full sequence through `r[220+count-1]` before selecting the requested slice.
The static helpers were not run.

The algorithm is attributed by Rosetta Code to Knuth's subtractive method in
*The Art of Computer Programming*, Volume 2, §3.2.2, Algorithm A, with Bentley's
seed permutation and warmup. The [RosettaGit task page](https://rosettagit.org/tasks/subtractive-generator/)
was used for the high-level algorithm description. The discovery title was located in the [popular-task index at pinned commit `1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks).

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/s/subtractive_prng_bentley_seeded_sequence.c`](../../../c/s/subtractive_prng_bentley_seeded_sequence.c) |
| C3 | [`c3/s/subtractive_prng_bentley_seeded_sequence.c3`](../../../c3/s/subtractive_prng_bentley_seeded_sequence.c3) |
| C++ | [`cpp/s/subtractive_prng_bentley_seeded_sequence.cpp`](../../../cpp/s/subtractive_prng_bentley_seeded_sequence.cpp) |
| Elisa | [`elisa/s/subtractive_prng_bentley_seeded_sequence.elisa`](../../../elisa/s/subtractive_prng_bentley_seeded_sequence.elisa) |
| Mojo | [`mojo/s/subtractive_prng_bentley_seeded_sequence.mojo`](../../../mojo/s/subtractive_prng_bentley_seeded_sequence.mojo) |
| Nim | [`nim/s/subtractive_prng_bentley_seeded_sequence.nim`](../../../nim/s/subtractive_prng_bentley_seeded_sequence.nim) |
| Odin | [`odin/s/subtractive_prng_bentley_seeded_sequence.odin`](../../../odin/s/subtractive_prng_bentley_seeded_sequence.odin) |
| Rust | [`rust/s/subtractive_prng_bentley_seeded_sequence.rs`](../../../rust/s/subtractive_prng_bentley_seeded_sequence.rs) |
| V | [`v/s/subtractive_prng_bentley_seeded_sequence.v`](../../../v/s/subtractive_prng_bentley_seeded_sequence.v) |
| Zig | [`zig/s/subtractive_prng_bentley_seeded_sequence.zig`](../../../zig/s/subtractive_prng_bentley_seeded_sequence.zig) |
