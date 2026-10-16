# Composite LFSR Majority Clock Step

This package isolates one call to the pinned Java `CompositeLFSR.clock()` for the three registers configured by `A5KeyStreamGenerator.initialize`. It accepts their current states directly, so it does not perform session-key/frame initialization, warm-up cycles, key-stream generation, or cipher XOR. It is a separate state-transition benchmark from [A5/1 key-stream generation](../../a/a5_key_stream_generator/README.md).

## Contract

- Input is exactly `[state1, state2, state3]`, with each register represented by a nonnegative integer bitmask. Bit `i` is source `BitSet.get(i)`.
- The source subclass configures register lengths `[19, 22, 23]`, clock-bit indexes `[8, 10, 10]`, and tap sets `[[13, 16, 17, 18], [20, 21], [7, 20, 21, 22]]`. State values must fit their register width.
- The clock step first computes the XOR of all three old last bits. It then finds the majority clock bit and shifts each register whose clock bit equals that majority. A shift inserts the XOR of the configured tap bits at bit 0 and moves each old bit `i` to bit `i+1`, discarding the old last bit.
- Output is `[output_bit, next_state1, next_state2, next_state3]`, each encoded as a signed little-endian i64. Success returns 32 bytes; invalid input returns `-1`; insufficient or null output capacity returns `-2` without writing.

[`workload.json`](workload.json) covers both majority decisions, selective and full clocking, old-last-bit output, tap feedback, unchanged registers, maximum states, invalid state widths, and output capacity. All nine ports passed 275 independent register-bit oracle inputs each and recorded 14 workload cases with [`benchmarks/verify_i64_array_bytes_output.py`](../../verify_i64_array_bytes_output.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/composite_lfsr_majority_clock.c`](../../../c/c/composite_lfsr_majority_clock.c) |
| C3 | [`c3/c/composite_lfsr_majority_clock.c3`](../../../c3/c/composite_lfsr_majority_clock.c3) |
| C++ | [`cpp/c/composite_lfsr_majority_clock.cpp`](../../../cpp/c/composite_lfsr_majority_clock.cpp) |
| Elisa | [`elisa/c/composite_lfsr_majority_clock.elisa`](../../../elisa/c/composite_lfsr_majority_clock.elisa) |
| Nim | [`nim/c/composite_lfsr_majority_clock.nim`](../../../nim/c/composite_lfsr_majority_clock.nim) |
| Odin | [`odin/c/composite_lfsr_majority_clock.odin`](../../../odin/c/composite_lfsr_majority_clock.odin) |
| Rust | [`rust/c/composite_lfsr_majority_clock.rs`](../../../rust/c/composite_lfsr_majority_clock.rs) |
| V | [`v/c/composite_lfsr_majority_clock.v`](../../../v/c/composite_lfsr_majority_clock.v) |
| Zig | [`zig/c/composite_lfsr_majority_clock.zig`](../../../zig/c/composite_lfsr_majority_clock.zig) |

## Upstream source

- [TheAlgorithms/Java `CompositeLFSR`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/CompositeLFSR.java)
- [TheAlgorithms/Java `A5KeyStreamGenerator` register configuration](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/A5KeyStreamGenerator.java)
- [TheAlgorithms/Java `LFSR` shift and feedback behavior](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/LFSR.java)

The pinned Java source is under the repository's [MIT license](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE).
