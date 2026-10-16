# Conway's Game of Life

Compute one generation of a square binary board using Conway's B3/S23 rules. The pinned Python source provides the same neighbor-count rules, but its NumPy slice at the top and left edges can become empty when the negative slice start is normalized. This benchmark follows the documented finite-board rules: cells outside every edge are dead and do not wrap around.

## Contract

- The `i64_array_bytes_output` input is `[side, cell_0, ..., cell_(side²-1)]`, with cells in row-major order.
- `side` is from 0 through 32, the array contains exactly `1 + side²` values, and each cell is 0 or 1. Invalid input returns `-1`.
- Return the next generation as one byte per cell, in row-major order. The return value is the output byte count. A cell lives next if it has exactly three live neighbors, or if it is already alive and has two or three live neighbors.
- If the output buffer is too small, return `-2` without writing.
- The maximum board has 1,024 cells, within the shared output buffer limit.

The independent verifier accumulates neighbor counts from live cells, then applies the birth/survival rules. It exhaustively checks all boards through side 3 and adds deterministic larger boards, boundary patterns, and malformed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/game_of_life.c`](../../../c/g/game_of_life.c) |
| C3 | [`c3/g/game_of_life.c3`](../../../c3/g/game_of_life.c3) |
| C++ | [`cpp/g/game_of_life.cpp`](../../../cpp/g/game_of_life.cpp) |
| Elisa | [`elisa/g/game_of_life.elisa`](../../../elisa/g/game_of_life.elisa) |
| Nim | [`nim/g/game_of_life.nim`](../../../nim/g/game_of_life.nim) |
| Odin | [`odin/g/game_of_life.odin`](../../../odin/g/game_of_life.odin) |
| Rust | [`rust/g/game_of_life.rs`](../../../rust/g/game_of_life.rs) |
| V | [`v/g/game_of_life.v`](../../../v/g/game_of_life.v) |
| Zig | [`zig/g/game_of_life.zig`](../../../zig/g/game_of_life.zig) |

Upstream: [TheAlgorithms/Python `game_of_life.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/game_of_life.py). The pinned [Python `conways_game_of_life.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/conways_game_of_life.py) and [JavaScript `ConwaysGameOfLife.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Cellular-Automata/ConwaysGameOfLife.js) implement the same finite-board B3/S23 generation and map to this benchmark as aliases. The image animation wrapper is not part of the contract.

Build with the `i64_array_bytes_output` ABI and verify with `python3 benchmarks/verify_game_of_life.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.
