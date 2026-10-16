# Coin change combination count

Count the ways to make change using an ordered list of reusable coin types.
This package preserves the exact indexing behavior of the pinned Go
`CoinChange`: the combination table has `amount` entries, the first entry is
initialized to one, and the function returns the entry at `amount - 1`.
Therefore the observable target is **amount minus one**, rather than amount.
Coins are processed in input order with ascending subtotal updates, so a coin
can be reused and permutations are not counted. Repeated equal denominations
remain separate coin types, matching the source loop.

## Contract

- Input is `[amount, coin_count, coin_0, ..., coin_(coin_count-1)]`.
- `amount` is 1 through 30; `coin_count` is 0 through 8; the array length must
  equal `coin_count + 2`.
- Each denomination is 1 through 30. Repeated denominations are accepted and
  counted as distinct listed types.
- Return the number of combinations that sum to `amount - 1` with unlimited
  reuse of each listed coin type. With no coin types, amount 1 returns 1 and
  any larger amount returns 0.
- Malformed or out-of-range input returns -1.
- The bound keeps the largest count at 8,347,680, within the source's int32
  result range.

This is distinct from [`coin_change`](../coin_change/README.md), which counts
the minimum number of coins rather than combinations.

## Workload and oracle

[`workload.json`](workload.json) covers the source's `amount - 1` indexing,
unlimited reuse, repeated coin types, oversized denominations, and invalid
arrays. The independent oracle uses a memoized recursion over coin types. Run
`python3 benchmarks/verify_i64_array_scalar.py --algorithms coinchange --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`
to check its registered scalar workload.

## Pinned source

[TheAlgorithms/Go `dynamic/coinchange.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/coinchange.go)
uses a one-dimensional combination table, coin types in the outer loop, and
ascending subtotal updates, then returns `combination[amount-1]`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/coinchange.c`](../../../c/c/coinchange.c) |
| C3 | [`c3/c/coinchange.c3`](../../../c3/c/coinchange.c3) |
| C++ | [`cpp/c/coinchange.cpp`](../../../cpp/c/coinchange.cpp) |
| Elisa | [`elisa/c/coinchange.elisa`](../../../elisa/c/coinchange.elisa) |
| Nim | [`nim/c/coinchange.nim`](../../../nim/c/coinchange.nim) |
| Odin | [`odin/c/coinchange.odin`](../../../odin/c/coinchange.odin) |
| Rust | [`rust/c/coinchange.rs`](../../../rust/c/coinchange.rs) |
| V | [`v/c/coinchange.v`](../../../v/c/coinchange.v) |
| Zig | [`zig/c/coinchange.zig`](../../../zig/c/coinchange.zig) |
