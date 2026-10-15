# Move Zeroes

This benchmark combines the C LeetCode 283 and Dart `move_zeroes` implementations. Both stably compact nonzero values toward the front, then fill the remaining positions with zero.

## Contract

- Input is an array of zero to 4,096 signed 32-bit integers.
- Invalid length or values outside the signed 32-bit range return `-1`.
- The output has the same length as the input: all nonzero values retain their relative order, followed by enough zeroes to restore the original length. Values are encoded as little-endian signed 32-bit integers. The return value is the output length.
- Insufficient output capacity returns `-2` before writing any bytes.
- Each port validates the input, compacts nonzero values in one forward pass, and fills the remaining output slots with zero in a second pass.

The C numeric filename `283` and Dart candidate `move_zeroes` share this behavior. The C candidate is canonical; the Dart candidate is recorded as an alias.

Run `python3 benchmarks/verify_move_zeroes.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short arrays, seeded arrays up to maximum length, signed boundaries, invalid values, output-capacity failure, and workload records.

## Implementations

Portable implementations are [`c/m/move_zeroes.c`](../../../c/m/move_zeroes.c), [`c3/m/move_zeroes.c3`](../../../c3/m/move_zeroes.c3), [`cpp/m/move_zeroes.cpp`](../../../cpp/m/move_zeroes.cpp), [`elisa/m/move_zeroes.elisa`](../../../elisa/m/move_zeroes.elisa), [`nim/m/move_zeroes.nim`](../../../nim/m/move_zeroes.nim), [`odin/m/move_zeroes.odin`](../../../odin/m/move_zeroes.odin), [`rust/m/move_zeroes.rs`](../../../rust/m/move_zeroes.rs), [`v/m/move_zeroes.v`](../../../v/m/move_zeroes.v), and [`zig/m/move_zeroes.zig`](../../../zig/m/move_zeroes.zig). They use generic compiler targets without architecture-specific instructions.

## Upstream references

- [TheAlgorithms/C LeetCode 283](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/283.c)
- [TheAlgorithms/Dart `move_zeroes`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/array/move_zeroes.dart)
