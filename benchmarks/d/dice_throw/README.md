# Dice throw

Count the ordered outcomes that produce a requested sum when throwing a fixed number of identical-sided dice.

## Contract

- The i64_array_scalar ABI receives exactly `[faces, dice, target]` as signed 64-bit integers.
- `faces` and `dice` must each be in `[1, 8]`; `target` must be in `[0, 64]`. Malformed arrays and values outside those bounds return `-1` under the benchmark ABI.
- The bounded domain keeps the source's `long` count exact and safely within signed 64-bit range. The largest possible count is `8^8`, which is below `2^53` as well.
- The dynamic program stores counts for each number of dice and each total. It initializes the one-die row to one way for each reachable face, then for each later row sums the previous-row counts for faces from `1` through `min(faces, total - 1)`, preserving the pinned loop bounds.
- Time is `O(dice * target * faces)` and auxiliary space is `O(dice * target)`.

## Source

This follows the pinned [TheAlgorithms/Java DiceThrow.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/DiceThrow.java), whose `findWays(faces, dice, target)` builds a two-dimensional `long` table and sums prior totals for each possible face.

## Workload and build

[`workload.json`](workload.json) covers one-die cases, boundary totals, standard multi-die examples, the maximum bounded dimensions, impossible totals, and malformed inputs. Build with the i64_array_scalar ABI and record with the shared runner:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm dice_throw --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/dice_throw/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms dice_throw
```

## Ports

| Language | Source |
| --- | --- |
| C | [c/d/dice_throw.c](../../../c/d/dice_throw.c) |
| C3 | [c3/d/dice_throw.c3](../../../c3/d/dice_throw.c3) |
| C++ | [cpp/d/dice_throw.cpp](../../../cpp/d/dice_throw.cpp) |
| Elisa | [elisa/d/dice_throw.elisa](../../../elisa/d/dice_throw.elisa) |
| Nim | [nim/d/dice_throw.nim](../../../nim/d/dice_throw.nim) |
| Odin | [odin/d/dice_throw.odin](../../../odin/d/dice_throw.odin) |
| Rust | [rust/d/dice_throw.rs](../../../rust/d/dice_throw.rs) |
| V | [v/d/dice_throw.v](../../../v/d/dice_throw.v) |
| Zig | [zig/d/dice_throw.zig](../../../zig/d/dice_throw.zig) |
