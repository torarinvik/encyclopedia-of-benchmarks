# Minimum coin change combinations

Count the unordered combinations that make a target using unlimited copies of each supplied denomination. This is the dynamic-programming source, separate from the greedy `minimum_coin_change_greedy` benchmark.

## Contract

- Input is a signed 64-bit integer array `[target, n, denomination_0, ...]`, with exact length `2 + n`.
- `target` is in `[-64, 64]`; `n` is in `[0, 32]`; denominations are strictly increasing integers in `[1, 64]`.
- Denominations are unlimited and combinations are unordered. The recurrence processes one coin at a time and increases the amount from that coin through the target.
- Negative targets return zero. A zero target returns one, including when the denomination list is empty. A positive target with no usable combination returns zero.
- Malformed input returns `-1`. The result is at most `p(64) = 1,747,163`, so signed 64-bit arithmetic is sufficient.

## Pinned source

[TheAlgorithms/Python dynamic_programming/minimum_coin_change.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_coin_change.py), function `dp_count`.

## Workload and oracle

[workload.json](workload.json) covers the pinned examples, negative and zero targets, empty denominations, impossible totals, upper bounds, malformed lengths, and denomination constraints. The independent oracle is [minimum_coin_change_combinations_oracle.py](../../minimum_coin_change_combinations_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/minimum_coin_change_combinations.c](../../../c/m/minimum_coin_change_combinations.c) |
| C3 | [c3/m/minimum_coin_change_combinations.c3](../../../c3/m/minimum_coin_change_combinations.c3) |
| C++ | [cpp/m/minimum_coin_change_combinations.cpp](../../../cpp/m/minimum_coin_change_combinations.cpp) |
| Elisa | [elisa/m/minimum_coin_change_combinations.elisa](../../../elisa/m/minimum_coin_change_combinations.elisa) |
| Nim | [nim/m/minimum_coin_change_combinations.nim](../../../nim/m/minimum_coin_change_combinations.nim) |
| Odin | [odin/m/minimum_coin_change_combinations.odin](../../../odin/m/minimum_coin_change_combinations.odin) |
| Rust | [rust/m/minimum_coin_change_combinations.rs](../../../rust/m/minimum_coin_change_combinations.rs) |
| V | [v/m/minimum_coin_change_combinations.v](../../../v/m/minimum_coin_change_combinations.v) |
| Zig | [zig/m/minimum_coin_change_combinations.zig](../../../zig/m/minimum_coin_change_combinations.zig) |
