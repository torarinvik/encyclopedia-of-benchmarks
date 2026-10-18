# LZ78 compression

This benchmark covers the pinned Java `LZ78.compress` operation. The paired `decompress` method is outside this compression contract so its reconstruction cost does not enter the measured call.

## Contract

Input is `[n, characters...]`, where `n` is 0 through 64 and must equal the number of following signed-i64 character codes. Each character code is printable ASCII in `[32,126]`; excluding NUL reserves code 0 for the source's end-of-stream token. The maximum valid input contains 65 words, and the maximum parseable input is 66 words for an extra-word framing probe.

The compressor grows a trie from the empty root. Dictionary index 0 denotes the empty prefix; each newly created phrase receives the next index starting at 1. On a missing trie edge, emit `(index_of_longest_matched_prefix, current_character)`, add the phrase to the trie, and restart at the root. If input ends while the current node is a nonempty phrase, emit `(that_phrase_index, 0)` as the source's end-of-stream token. Empty input emits no tokens.

Output is a sequence of token pairs encoded as little-endian signed-i64 words: `[index0, character0, index1, character1, ...]`. There is no count prefix; the byte result length determines the token count. The maximum output is 64 tokens, or 1024 bytes. A valid call returns the number of bytes written.

Malformed framing, unsupported lengths, or non-printable-ASCII input returns `-1` before output checks. A null output pointer or capacity below the encoded result length returns `-2` after input validation. Error returns write no bytes. Empty input with a nonnull zero-capacity output succeeds with result 0; a null output pointer returns `-2` even for empty input.

The independent oracle is [`../../lz78_oracle.py`](../../lz78_oracle.py). The workload includes empty and single-character input, repeated phrases, a final incomplete phrase, printable-ASCII boundaries, maximum output, malformed framing, and output-capacity edges.

## Pinned source

- Java [`LZ78.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/LZ78.java), specifically `LZ78.compress(String)`, emits dictionary-prefix/next-character tokens and uses NUL for a final partial phrase.

## Language ports

| Language | Port |
|---|---|
| C | [`c/l/lz78.c`](../../../c/l/lz78.c) |
| C3 | [`c3/l/lz78.c3`](../../../c3/l/lz78.c3) |
| C++ | [`cpp/l/lz78.cpp`](../../../cpp/l/lz78.cpp) |
| Elisa | [`elisa/l/lz78.elisa`](../../../elisa/l/lz78.elisa) |
| Nim | [`nim/l/lz78.nim`](../../../nim/l/lz78.nim) |
| Odin | [`odin/l/lz78.odin`](../../../odin/l/lz78.odin) |
| Rust | [`rust/l/lz78.rs`](../../../rust/l/lz78.rs) |
| V | [`v/l/lz78.v`](../../../v/l/lz78.v) |
| Zig | [`zig/l/lz78.zig`](../../../zig/l/lz78.zig) |
