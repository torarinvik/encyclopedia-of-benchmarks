# Word ladder (Java shortest length)

## Contract

This package follows the pinned Java `WordLadder.ladderLength`: breadth-first search through a dictionary of fixed-width lowercase ASCII words, returning the number of words in a shortest transformation sequence (including both endpoints), or zero if no sequence exists. A move changes exactly one character. The end word must occur in the dictionary.

Inputs are signed 64-bit arrays `[word_length, begin_code, end_code, dictionary_count, dictionary_codes...]`. Word codes are base 26 with `a=0` through `z=25`, with the leftmost character as the least significant digit. Width is 1 through 5, dictionary count is 0 through 32, and codes must fit the width. Duplicate dictionary words have no effect. The Java neighbor order is character position from left to right, then replacement `a` through `z`; the returned length does not expose tie paths. Invalid inputs return `-1`. The C ABI is `int64_t word_ladder(const int64_t *input, size_t length, uint8_t *output, size_t capacity)`. On success it writes one little-endian signed i64 containing the ladder length (including zero for no path) and returns 8 bytes; insufficient or null output returns `-2`.

## Source discrepancy

The pinned Python `word_ladder` is a separate DFS backtracking API: it returns the first path found rather than the shortest length. It mutates the passed word set while searching, may include `begin_word` twice when it appears in that set, and is order-sensitive to character/replacement iteration. This Java benchmark does not claim Python behavioral parity. A dedicated Python DFS benchmark would need a separate contract and output representation.

## Workload and oracle

See [`workload.json`](workload.json). The independent oracle is [`benchmarks/word_ladder_oracle.py`](../../word_ladder_oracle.py).

## Pinned source

- [Java `WordLadder.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/WordLadder.java)
- [Python `word_ladder.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/word_ladder.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/word_ladder.c`](../../../c/w/word_ladder.c) |
| C3 | [`c3/w/word_ladder.c3`](../../../c3/w/word_ladder.c3) |
| C++ | [`cpp/w/word_ladder.cpp`](../../../cpp/w/word_ladder.cpp) |
| Elisa | [`elisa/w/word_ladder.elisa`](../../../elisa/w/word_ladder.elisa) |
| Nim | [`nim/w/word_ladder.nim`](../../../nim/w/word_ladder.nim) |
| Odin | [`odin/w/word_ladder.odin`](../../../odin/w/word_ladder.odin) |
| Rust | [`rust/w/word_ladder.rs`](../../../rust/w/word_ladder.rs) |
| V | [`v/w/word_ladder.v`](../../../v/w/word_ladder.v) |
| Zig | [`zig/w/word_ladder.zig`](../../../zig/w/word_ladder.zig) |
