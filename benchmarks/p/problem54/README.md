# Project Euler Problem 54: Poker Hands

## Contract

The pinned no-argument solution reads 1,000 deals from `poker_hands.txt` and counts wins for Player 1. Each row gives Player 1's five cards followed by Player 2's five cards. The fixed result is 376.

The benchmark adapts the adjacent source data to the `i64_array_scalar` ABI: each deal is ten card IDs flattened in file order. A card ID is `(rank_index * 4) + suit_index`, where ranks run from 2 through Ace and suits are Clubs, Diamonds, Hearts, Spades. Each deal must contain ten distinct IDs. Invalid input returns -1.

The ports rank five-card hands by category and then by the source's rank and kicker ordering. They normalize an Ace-low straight to five-high; suits never break ties. A tied deal adds no Player 1 win. The workload supplies the pinned 1,000-deal data directly, so the compiled programs need no file or network access.

## Pinned dataset and license

[`poker_hands.txt`](poker_hands.txt) is copied verbatim from TheAlgorithms/Python at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, path `project_euler/problem_054/poker_hands.txt`. The upstream repository is MIT-licensed; the data file has no separate per-file notice. See this repository's root [LICENSE.md](../../../LICENSE.md). The workload's `dataset_sha256` records the bundled file's digest.

The pinned Python solution and its data are available at:

- [Python sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_054/sol1.py)
- [poker_hands.txt](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_054/poker_hands.txt)

## Workload

The workload includes the full 1,000-deal dataset and a wrong-length input. It uses three samples, one warmup, and one call per sample because each call evaluates all 1,000 hands.

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm problem54 --language rust

Run it with:

    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/p/problem54/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem54.c](../../../c/p/problem54.c) |
| C3 | [c3/p/problem54.c3](../../../c3/p/problem54.c3) |
| C++ | [cpp/p/problem54.cpp](../../../cpp/p/problem54.cpp) |
| Elisa | [elisa/p/problem54.elisa](../../../elisa/p/problem54.elisa) |
| Nim | [nim/p/problem54.nim](../../../nim/p/problem54.nim) |
| Odin | [odin/p/problem54.odin](../../../odin/p/problem54.odin) |
| Rust | [rust/p/problem54.rs](../../../rust/p/problem54.rs) |
| V | [v/p/problem54.v](../../../v/p/problem54.v) |
| Zig | [zig/p/problem54.zig](../../../zig/p/problem54.zig) |
