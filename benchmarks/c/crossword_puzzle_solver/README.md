# Crossword Puzzle Solver

This benchmark ports the pinned Python backtracker. It places words in stable longest-first order, scans every grid cell row-major, and tries vertical before horizontal placement. Existing letters may be shared when they match. Failed branches remove only the letters that branch added, preserving preset and crossing letters. The solver succeeds after placing all words; an empty word list succeeds without changing the board.

## Contract

- Input is `[rows, columns, word_count, row-major cells..., (word_length, uppercase ASCII letters...)...]`.
- Rows and columns are each 1 through 8. There are 0 through 8 words, each 1 through 8 uppercase ASCII letters. Duplicate words are allowed, as in the source.
- Cell value `0` means empty, `-1` means blocked, and `65` through `90` are preset uppercase letters. A placement can use an empty cell or a cell containing the same letter.
- Output is `[solved (0 or 1), row-major cells...]`, encoded as little-endian signed 64-bit values. The function returns the output byte count, `-1` for malformed input, and `-2` for insufficient output capacity.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm crossword_puzzle_solver --language cpp --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/crossword_puzzle_solver/cpp/build.json
```

## Pinned source

- Python [`crossword_puzzle_solver.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/crossword_puzzle_solver.py)
