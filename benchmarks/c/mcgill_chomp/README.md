# McGill Chomp

This package ports the outcome-solving core of the `chomp` launcher in the pinned `lac-dcc/Benchmarks` McGill suite. The source has its interactive mode selection disabled and selects report-game mode 2. That mode fixes the board width at seven columns and uses seven rows for `SMALL_PROBLEM_SIZE`, or eight rows otherwise.

## Bounded contract

- ABI: `scalar_call`, function symbol `mcgill_chomp`.
- Input is the launcher's row count: 7 for the small profile or 8 for the default profile. The column count remains fixed at 7.
- Each board state stores the remaining height of each column, left to right. Valid states have non-increasing heights. A move at `(row, column)` caps that column and every column to its right at `row`, matching `make_data` followed by `melt_data`.
- The solver evaluates the full state graph in the source's row-major move order. A state wins when it has a move to a losing state. The empty board has value 1: the previous player took the poison square, so the player now to move wins.
- The scalar result is the initial state's value, 1 for a first-player win and 0 for a first-player loss. The upstream prompts and move-by-move report are presentation output and are not included in the scalar ABI.
- The 8-by-7 profile has 6,435 legal board shapes. The ports bound their table to the 9^7 base-address space (under 4.8 MB); Elisa uses combinatorial ranking to store only the 6,435 legal shapes.
- Invalid row profiles return -1. The workload covers both pinned launcher profiles, invalid bounds, and signed 64-bit extremes.
- The independent oracle uses memoized recursion over resulting board shapes rather than the ports' source-order state-table traversal.

## Pinned provenance and license

- [`chomp.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/chomp/chomp.c), commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/chomp/info.sh) names the executable `chomp`, lists `chomp.c`, passes no run options, and supplies `-lm` at compile time.
- The repository snapshot declares no license, and `chomp.c` has no explicit license grant. These ports are independently written from the observed recurrence and rules; the upstream implementation is not copied.

## Language ports

| Language | Implementation |
| --- | --- |
| C | [`c/mcgill_chomp.c`](../../../c/mcgill_chomp.c) |
| C3 | [`c3/mcgill_chomp.c3`](../../../c3/mcgill_chomp.c3) |
| C++ | [`cpp/mcgill_chomp.cpp`](../../../cpp/mcgill_chomp.cpp) |
| Elisa | [`elisa/m/mcgill_chomp.elisa`](../../../elisa/m/mcgill_chomp.elisa) |
| Nim | [`nim/mcgill_chomp.nim`](../../../nim/mcgill_chomp.nim) |
| Odin | [`odin/m/mcgill_chomp.odin`](../../../odin/m/mcgill_chomp.odin) |
| Rust | [`rust/mcgill_chomp.rs`](../../../rust/mcgill_chomp.rs) |
| V | [`v/m/mcgill_chomp.v`](../../../v/m/mcgill_chomp.v) |
| Zig | [`zig/mcgill_chomp.zig`](../../../zig/mcgill_chomp.zig) |

The source-backed workload is [`workload.json`](workload.json); the independent oracle is [`benchmarks/mcgill_chomp_oracle.py`](../../mcgill_chomp_oracle.py).
