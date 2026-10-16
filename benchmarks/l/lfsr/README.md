# Linear feedback shift register

This package models the concrete configurable Java `LFSR` class independently from the three-register A5/1 key-stream generator. It preserves the source's tap XOR, bit ordering, and shift direction.

Input is `[register_width, clock_bit_index, tap_count, clock_count, session_key_bits, frame_counter, tap_indices...]` in signed 64-bit slots. Register width is 1 through 63; the clock-bit and tap indexes must be within the register. Tap indexes may repeat, matching the source's XOR behavior. The session key is treated as a raw 64-bit bit pattern, and the frame counter is 0 through 4,194,303 (22 bits). `clock_count` is 0 through 256. The input must contain exactly `6 + tap_count` slots. Malformed inputs return `-1`.

Initialization clears the register, then processes key bits 63 down to 0 and frame bits 21 down to 0. Each fed bit is XORed with the current tapped-bit parity and inserted at bit 0 while existing register bits shift toward higher indexes; the old highest bit is discarded. Each requested clock returns that discarded highest bit before applying the tapped-bit XOR transition.

Output is `[clock_count, output_bits..., final_register_state]` as little-endian signed 64-bit values. The final state packs register bit `i` into integer bit `i`. A null or undersized output buffer returns `-2`; success returns the byte length.

| Language | Port |
|---|---|
| C | [`c/l/lfsr.c`](../../../c/l/lfsr.c) |
| C3 | [`c3/l/lfsr.c3`](../../../c3/l/lfsr.c3) |
| C++ | [`cpp/l/lfsr.cpp`](../../../cpp/l/lfsr.cpp) |
| Elisa | [`elisa/l/lfsr.elisa`](../../../elisa/l/lfsr.elisa) |
| Nim | [`nim/l/lfsr.nim`](../../../nim/l/lfsr.nim) |
| Odin | [`odin/l/lfsr.odin`](../../../odin/l/lfsr.odin) |
| Rust | [`rust/l/lfsr.rs`](../../../rust/l/lfsr.rs) |
| V | [`v/l/lfsr.v`](../../../v/l/lfsr.v) |
| Zig | [`zig/l/lfsr.zig`](../../../zig/l/lfsr.zig) |

Pinned source: [TheAlgorithms/Java `LFSR.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/LFSR.java). Its `BaseLFSR` interface is excluded as a separate benchmark because it declares no transition behavior. The three-register [`a5_key_stream_generator`](../../a/a5_key_stream_generator/README.md) remains a distinct composition benchmark.
