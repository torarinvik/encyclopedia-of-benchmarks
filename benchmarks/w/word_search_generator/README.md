# Word Search Generator

Construct a board by placing words in one of eight compass directions. This is a board-construction benchmark; it is separate from `word_search`, which searches an existing board for a path.

## Contract

- Input is a packed signed 64-bit array: `[width, height, seed, word_count, word_length, ASCII bytes..., ...]`.
- Width and height are in `1..=32`; seed is in `1..=2,147,483,646`; word count is in `0..=96`; each word has `1..=32` ASCII letters. The packed input has at most 4,096 values.
- The board starts empty. Words are processed in input order. Each word is assigned one direction from north, northeast, east, southeast, south, southwest, west, northwest. The algorithm shuffles row candidates, then column candidates, then selects a direction. It places the word at the first in-bounds candidate whose cells are all empty. It never overlaps letters. If no candidate fits, that word is skipped.
- The original Python source uses the process-wide random generator. The benchmark makes that selection reproducible with the recurrence `state = (state * 48,271) mod 2,147,483,647`; each shuffled list uses Fisher-Yates with `next_random() mod remaining`. The seed and call order are part of this contract.
- Output is `width * height` bytes in row-major order. Empty cells are byte `0`; occupied cells contain their ASCII letter. The return value is the number of output bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`.

The ports use fixed arrays bounded by the contract. Their worst-case time is `O(word_count * (height + width + height * width * word_length))`; auxiliary space is `O(width * height)`.

## Workload and verification

[`workload.json`](workload.json) covers all eight directions, multiword placement, an unplaceable word, an empty word list, and malformed inputs. Build and run with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm word_search_generator --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/w/word_search_generator/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/word_search_generator.c`](../../../c/w/word_search_generator.c) |
| C3 | [`c3/w/word_search_generator.c3`](../../../c3/w/word_search_generator.c3) |
| C++ | [`cpp/w/word_search_generator.cpp`](../../../cpp/w/word_search_generator.cpp) |
| Elisa | [`elisa/w/word_search_generator.elisa`](../../../elisa/w/word_search_generator.elisa) |
| Nim | [`nim/w/word_search_generator.nim`](../../../nim/w/word_search_generator.nim) |
| Odin | [`odin/w/word_search_generator.odin`](../../../odin/w/word_search_generator.odin) |
| Rust | [`rust/w/word_search_generator.rs`](../../../rust/w/word_search_generator.rs) |
| V | [`v/w/word_search_generator.v`](../../../v/w/word_search_generator.v) |
| Zig | [`zig/w/word_search_generator.zig`](../../../zig/w/word_search_generator.zig) |

## Reviewed source

The pinned [Python `other/word_search.py` source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/word_search.py) shuffles candidate rows and columns, chooses one of eight compass directions for each word, and inserts only where every destination cell is empty. It skips a word when no placement succeeds in its chosen direction.
