# Shootout random number generator

## Contract

Run the pinned Shootout linear congruential generator for a bounded positive number of calls. The generator starts at state 42 and each call updates the state with `(state * 3877 + 29573) % 139968`. After the requested calls, return the source's final value `100.0 * state / 139968` formatted with nine fractional digits and a line feed. The source launcher defaults to 400,000,000 calls; `SMALL_PROBLEM_SIZE` changes that compile-time default to 40,000,000. This suite profile accepts 1 through 1,000,000 calls.

The C ABI entry point is:

~~~c
int64_t shootout_random(int64_t call_count, uint8_t *output,
                        size_t output_capacity);
~~~

The call count must be in 1..1,000,000. Invalid counts return -1. Success returns the number of ASCII bytes written, including the final line feed. A null output pointer or a buffer shorter than the formatted result returns -2 without writing. The output is at most 13 bytes. Ports stage the complete line before copying it to the caller's buffer.

The oracle computes the recurrence's affine transform by exponentiation by squaring, independently of the per-call loop used by the language ports. It then rounds `100 * state / 139968` to nine decimal places using integer arithmetic and emits the source's fixed-point line.

## Workload

[workload.json](workload.json) covers small call counts, the maximum bounded profile, invalid signed-i64 values, and null or insufficient output buffers. Each valid call starts from state 42, matching the source's process-static initialization for one benchmark invocation.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/shootout_random.c](../../../c/s/shootout_random.c) |
| C3 | [c3/s/shootout_random.c3](../../../c3/s/shootout_random.c3) |
| C++ | [cpp/s/shootout_random.cpp](../../../cpp/s/shootout_random.cpp) |
| Elisa | [elisa/s/shootout_random.elisa](../../../elisa/s/shootout_random.elisa) |
| Nim | [nim/s/shootout_random.nim](../../../nim/s/shootout_random.nim) |
| Odin | [odin/s/shootout_random.odin](../../../odin/s/shootout_random.odin) |
| Rust | [rust/s/shootout_random.rs](../../../rust/s/shootout_random.rs) |
| V | [v/s/shootout_random.v](../../../v/s/shootout_random.v) |
| Zig | [zig/s/shootout_random.zig](../../../zig/s/shootout_random.zig) |

## Pinned source

- [random.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/random/random.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/random/info.sh)
