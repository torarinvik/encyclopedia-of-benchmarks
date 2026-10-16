# Word Boggle

Search a rectangular ASCII character board for every dictionary word that can be formed from adjacent cells. A path may use horizontal, vertical, and diagonal neighbors, and may not reuse a cell. Return the distinct matches in bytewise lexicographic order, each followed by NUL. The deterministic ordering normalizes the pinned Java method's `HashSet` result.

## Contract

The signed 64-bit input is `[rows, columns, row-major board character codes, word_count, then repeated (word_length, word character codes)]`. Rows and columns are 1..6, there are 0..32 dictionary words, each word has 1..15 ASCII letters, and board rows are rectangular. Letter case is significant. Invalid inputs return `-1` with no output. A valid empty match set returns zero output bytes.

## Algorithm and verification

The pinned Java implementation builds a trie, starts a depth-first traversal at every board cell, follows all eight neighbors, and backtracks its per-path visited marks. Its `visited` matrix assumes a square board because both dimensions are allocated from `board.length`; this benchmark uses a correctly sized flat visited array and extends the same search to rectangular boards. The ports preserve trie-pruned search and cell reuse restrictions. `workload.json` covers diagonal paths, duplicate dictionary entries, case sensitivity, words longer than the board, and empty dictionaries.

Source: [TheAlgorithms Java `WordBoggle.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/puzzlesandgames/WordBoggle.java).

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
