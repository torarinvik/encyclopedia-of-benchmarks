# A5/1 cipher

This benchmark follows the pinned Java A5/1 implementation. It initializes three LFSRs from a 64-bit session-key BitSet and a 22-bit frame-counter BitSet, performs 100 majority-clocked warm-up cycles, emits 228 bits, and XORs those bits with the plaintext BitSet. Sequential blocks advance the frame counter; the Java `resetCounter()` behavior corresponds to starting a new benchmark call with the original input frame counter.

Source components: [A5Cipher](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/A5Cipher.java), [A5KeyStreamGenerator](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/A5KeyStreamGenerator.java), [CompositeLFSR](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/CompositeLFSR.java), and [LFSR](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/a5/LFSR.java).

Verify the byte-output implementations with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm a5_cipher --languages rust`.

## Contract

Input is packed signed-i64 slots: `[session_key_bits, initial_frame_bits, block_count, plaintext words...]`. `session_key_bits` and each plaintext word are interpreted as raw two's-complement bit patterns. `initial_frame_bits` uses its low 22 bits, with bit `i` mapping directly to Java `BitSet.get(i)`; this preserves the source's reverse-index frame increment convention. `block_count` is 1 through 4. Each block contains four little-endian 64-bit words for plaintext BitSet indices 0 through 255. The packed array length must equal `3 + 4 * block_count`.

Output is 32 bytes per block, little-endian by BitSet index. The first 228 bits are plaintext XOR the source key stream; bits 228 through 255 pass through unchanged, matching Java `BitSet.xor`. Output blocks use sequential frame counters, incremented exactly as `Utils.increment` does. The function returns output byte count, `-1` for malformed input, or `-2` when capacity is insufficient.

This fixed-width projection retains trailing zero bits that Java's variable-length `BitSet` representation omits. All supported inputs are bounded to 256 plaintext bits and four sequential blocks.
