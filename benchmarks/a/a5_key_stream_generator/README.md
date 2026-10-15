# A5/1 key-stream generator

This benchmark follows the pinned Java `A5KeyStreamGenerator`. It initializes three LFSRs from a 64-bit session key and a 22-bit frame counter, performs 100 majority-clocked warm-up cycles, and returns the next 228 generated bits. After each stream, it increments the frame counter and reinitializes the LFSRs for the following stream. The [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/A5KeyStreamGenerator.java) specifies these transitions; the cipher benchmark separately covers XOR with plaintext.

## Contract

Input is exactly three signed-i64 slots: `[session_key_bits, initial_frame_bits, stream_count]`. The key and frame values are interpreted as raw two's-complement bit patterns; only the low 22 frame bits are used. `stream_count` is from 1 through 4.

Each output stream occupies 29 bytes. Bits 0 through 227 are packed low-bit first; the upper four bits of byte 28 are zero. Streams after the first use sequential frame-counter values with the source's BitSet index order. The function returns the total output byte count, `-1` for malformed input, or `-2` when the output capacity is too small. This fixed-width projection retains trailing zero bits that Java's variable-length `BitSet` representation omits.
