# Project Euler Problem 13: Chunked large sum

This package benchmarks the generic `largeSum` routine from TheAlgorithms/JavaScript. The input is one concatenated decimal byte string; every 50 bytes form one chunk.

## Contract

- Input is `[byte_length, digit_0, ..., digit_(byte_length-1)]`. The payload length is 1 through 5,000 and every payload value is an ASCII digit byte (`48..57`). The maximum input vector has 5,001 signed 64-bit values, including the length header.
- The source sums columns from right to left using the first chunk's width. Chunks are split at offsets 0, 50, 100, and so on. A shorter final chunk stays left-aligned; missing `charAt` positions contribute zero, which is equivalent to padding that chunk with zeroes on the right. For example, 50 zeroes followed by `7` produce a prefix of `7000000000`.
- The output is the first ten characters of the source's decimal sum. Leading zeroes are preserved. The output length is 1 through 10 bytes; a single input shorter than ten digits returns that same short width (`000` returns `000`).
- Success returns the output byte length. Empty input, malformed lengths, or non-digit bytes return `-1`. Null output or capacity below the actual output length returns `-2`, without writing. The maximum output buffer is 10 bytes.

## Workload

[`workload.json`](workload.json) covers short outputs, preserved leading zeroes, carries between full chunks, the source's right-padding behavior for a partial final chunk, malformed inputs, output capacity, and the 5,000-byte maximum input.

## Pinned source

TheAlgorithms/JavaScript [`Problem013.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Project-Euler/Problem013.js), commit `5c39e87a9a31f279c60f830ad74a845e4788a517`, function `largeSum(bignum)`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/problem13_chunks.c`](../../../c/p/problem13_chunks.c) |
| C3 | [`c3/p/problem13_chunks.c3`](../../../c3/p/problem13_chunks.c3) |
| C++ | [`cpp/p/problem13_chunks.cpp`](../../../cpp/p/problem13_chunks.cpp) |
| Elisa | [`elisa/p/problem13_chunks.elisa`](../../../elisa/p/problem13_chunks.elisa) |
| Nim | [`nim/p/problem13_chunks.nim`](../../../nim/p/problem13_chunks.nim) |
| Odin | [`odin/p/problem13_chunks.odin`](../../../odin/p/problem13_chunks.odin) |
| Rust | [`rust/p/problem13_chunks.rs`](../../../rust/p/problem13_chunks.rs) |
| V | [`v/p/problem13_chunks.v`](../../../v/p/problem13_chunks.v) |
| Zig | [`zig/p/problem13_chunks.zig`](../../../zig/p/problem13_chunks.zig) |
