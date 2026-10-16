# Crossword Solver

This benchmark ports the pinned Java backtracking routine. It fills the first blank cell in row-major order, tries remaining words in their current list order, and tries vertical placement before horizontal placement. A placement is valid only when every covered cell is blank. The source stops successfully when no blank cells remain, even if the word list still contains unused words.

This differs from `crossword_puzzle_solver`, which orders words longest-first and permits matching letters at intersections.

## Contract

- Input is `[rows, columns, word_count, row-major cells..., (word_length, uppercase ASCII letters...)...]`.
- Rows and columns are each 1 through 8. There are 0 through 8 words, each 1 through 8 uppercase ASCII letters; duplicate words are outside the bounded benchmark domain.
- Cell value `0` means blank, `-1` means blocked, and `65` through `90` are fixed nonblank cells. The pinned source treats all nonblank cells as blockers.
- Search order matches the pinned Java routine, including appending a restored word to the end of its remaining list after a failed branch.
- Output is `[solved (0 or 1), row-major cells...]`, encoded as little-endian signed 64-bit values. The function returns the output byte count, `-1` for malformed input, and `-2` for insufficient output capacity.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm crossword_solver --language cpp --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/crossword_solver/cpp/build.json
```

## Pinned source

- Java [`CrosswordSolver.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/CrosswordSolver.java)
