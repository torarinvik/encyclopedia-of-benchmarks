# All construct

Return every ordered way to build a target string by concatenating entries from a word bank. The pinned Java and Python sources both use a position-indexed dynamic-programming table. They iterate target positions, then word-bank entries, then existing partial constructions, preserving that order and retaining duplicate word-bank entries as duplicate constructions.

Sources: [Java `AllConstruct.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/AllConstruct.java) and [Python `all_construct.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/all_construct.py).

## Contract

Input is `[target_length, target_ascii..., word_count, word_length, word_ascii..., ...]`. Target length is 0 through 6, word count is 0 through 4, and each word is 1 through 6 lowercase ASCII letters. The packed input length must be exact. Nonempty words avoid zero-length cycles; these bounds cap the result at 4,096 constructions.

Verify the nine implementations against the independent bounded oracle with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm all_construct
```

Output is a binary sequence of rows. Each row begins with a one-byte word count, followed by each source word as a one-byte length and its ASCII bytes. It therefore preserves the constructed strings and duplicate output rows exactly; it does not expose which duplicate bank entry produced a row. The return value is the number of constructions; malformed input returns `-1`, and insufficient capacity returns `-2`. An empty target has one construction, encoded as a single zero byte; an unconstructible target returns zero rows and zero output bytes.

| Language | Source |
| --- | --- |
| C | [`c/a/all_construct.c`](../../../c/a/all_construct.c) |
| C3 | [`c3/a/all_construct.c3`](../../../c3/a/all_construct.c3) |
| C++ | [`cpp/a/all_construct.cpp`](../../../cpp/a/all_construct.cpp) |
| Elisa | [`elisa/a/all_construct.elisa`](../../../elisa/a/all_construct.elisa) |
| Nim | [`nim/a/all_construct.nim`](../../../nim/a/all_construct.nim) |
| Odin | [`odin/a/all_construct.odin`](../../../odin/a/all_construct.odin) |
| Rust | [`rust/a/all_construct.rs`](../../../rust/a/all_construct.rs) |
| V | [`v/a/all_construct.v`](../../../v/a/all_construct.v) |
| Zig | [`zig/a/all_construct.zig`](../../../zig/a/all_construct.zig) |
