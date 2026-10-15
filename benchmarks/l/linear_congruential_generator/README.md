# Linear congruential generator

Generate a deterministic sequence with the recurrence `state = (multiplier * state + increment) % modulo`. The output contains the new state after each recurrence step, not the initial seed.

## Contract

- The `i64_array_bytes_output` input is `[seed, multiplier, increment, modulo, count]`.
- `modulo` is 2..2^32, `seed` is 0..modulo-1, `multiplier` is 0..65,535, `increment` is 0..2^32-1, and `count` is 0..512.
- Each generated state is an integer in 0..modulo-1 and is written as one little-endian unsigned 64-bit word. Return the number of bytes written, `8*count`.
- Invalid packing or values return `-1`; output capacity below `8*count`, or a missing output buffer when bytes are required, returns `-2`. A count of zero returns 0 bytes.
- The parameter bounds keep the integer product plus increment below 2^53, so Java's binary64 arithmetic preserves the same exact integer recurrence as Python's integer arithmetic. The bounded ABI uses an explicit seed; it excludes the sources' time-based default seed.

## Sources and related algorithms

The sources are Java [`LinearCongruentialGenerator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/LinearCongruentialGenerator.java) and Python [`linear_congruential_generator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/linear_congruential_generator.py). Both store a state, then apply the same recurrence on each `nextNumber`/`next_number` call. The separately named `sort_utils_random_generator` inventory candidate concerns sort utilities and is not this parameterized recurrence.

[`workload.json`](workload.json) covers small deterministic streams, zero state, a zero-length stream, modulus boundaries, and invalid parameters. The nine ports use the existing `i64_array_bytes_output` ABI.

| Language | Source |
| --- | --- |
| C | [`c/l/linear_congruential_generator.c`](../../../c/l/linear_congruential_generator.c) |
| C3 | [`c3/l/linear_congruential_generator.c3`](../../../c3/l/linear_congruential_generator.c3) |
| C++ | [`cpp/l/linear_congruential_generator.cpp`](../../../cpp/l/linear_congruential_generator.cpp) |
| Elisa | [`elisa/l/linear_congruential_generator.elisa`](../../../elisa/l/linear_congruential_generator.elisa) |
| Nim | [`nim/l/linear_congruential_generator.nim`](../../../nim/l/linear_congruential_generator.nim) |
| Odin | [`odin/l/linear_congruential_generator.odin`](../../../odin/l/linear_congruential_generator.odin) |
| Rust | [`rust/l/linear_congruential_generator.rs`](../../../rust/l/linear_congruential_generator.rs) |
| V | [`v/l/linear_congruential_generator.v`](../../../v/l/linear_congruential_generator.v) |
| Zig | [`zig/l/linear_congruential_generator.zig`](../../../zig/l/linear_congruential_generator.zig) |
