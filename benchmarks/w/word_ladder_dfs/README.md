# word_ladder_dfs

This package ports the pinned Python backtracking implementation in [`backtracking/word_ladder.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/word_ladder.py). It is distinct from the Java shortest-length `word_ladder`: this function returns the first DFS path and mutates its input set.

## Contract

- Input is `[word_length, begin_code, end_code, dictionary_count, sorted unique dictionary_codes...]`. Words contain lowercase ASCII letters, have fixed width `1..5`, and use ordinary base-26 encoding with the leftmost character most significant. Dictionary codes are strictly increasing, which also sorts the decoded words lexicographically. The set contains at most eight words to bound backtracking work.
- The search changes positions from left to right and replacement letters from `a` to `z`. It removes a candidate word while descending, restores it after a failed branch, and leaves selected path words removed after success. If `begin_word` is in the set, the self-transformation can add it to the path a second time. If the target is absent, the source returns an empty path without changing the set.
- Output is `[path_count, path_codes..., remaining_set_count, remaining_set_codes...]`, encoded as signed 64-bit little-endian values. The remaining set is emitted in the original sorted order. A successful call returns the output byte length; invalid input returns `-1`, and insufficient or null output capacity returns `-2`.

The independent oracle is [`benchmarks/word_ladder_dfs_oracle.py`](../../word_ladder_dfs_oracle.py). The workload covers first-path ordering, a DFS path longer than the shortest path, set restoration/mutation, repeated begin words, source examples, and validation/capacity cases.

Pinned source: [TheAlgorithms/Python `word_ladder.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/word_ladder.py).

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm word_ladder_dfs --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_bytes_output.py --algorithm word_ladder_dfs

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/word_ladder_dfs.c](../../../c/w/word_ladder_dfs.c) |
| C3 | [c3/w/word_ladder_dfs.c3](../../../c3/w/word_ladder_dfs.c3) |
| C++ | [cpp/w/word_ladder_dfs.cpp](../../../cpp/w/word_ladder_dfs.cpp) |
| Elisa | [elisa/w/word_ladder_dfs.elisa](../../../elisa/w/word_ladder_dfs.elisa) |
| Nim | [nim/w/word_ladder_dfs.nim](../../../nim/w/word_ladder_dfs.nim) |
| Odin | [odin/w/word_ladder_dfs.odin](../../../odin/w/word_ladder_dfs.odin) |
| Rust | [rust/w/word_ladder_dfs.rs](../../../rust/w/word_ladder_dfs.rs) |
| V | [v/w/word_ladder_dfs.v](../../../v/w/word_ladder_dfs.v) |
| Zig | [zig/w/word_ladder_dfs.zig](../../../zig/w/word_ladder_dfs.zig) |
