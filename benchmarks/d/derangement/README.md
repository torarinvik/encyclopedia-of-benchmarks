# Derangement count

Count derangements with the recurrence used by the pinned Python source. The shared signed 64-bit contract accepts `n` from 0 through 20 and returns `-1` outside that range.

## Contract

- `D(0) = 0` and `D(1) = 0`, matching the source's explicit base cases.
- `D(2) = 1`.
- For `n >= 3`, `D(n) = (n - 1) * (D(n - 1) + D(n - 2))`.
- The result for 0 through 20 fits in signed 64-bit arithmetic. Values below 0 or above 20 return `-1`.
- The implementation runs in `O(n)` time and `O(1)` auxiliary space.

The zero-object result intentionally follows the pinned function's behavior (`0`) rather than the conventional combinatorial value `D(0) = 1`. The input bound keeps every result representable by the scalar ABI.

## Workload

[`workload.json`](workload.json) covers both source base cases, the recurrence boundary, published examples, the largest supported input, and both sides of the supported domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/derangement.c`](../../../c/d/derangement.c) |
| C3 | [`c3/d/derangement.c3`](../../../c3/d/derangement.c3) |
| C++ | [`cpp/d/derangement.cpp`](../../../cpp/d/derangement.cpp) |
| Elisa | [`elisa/d/derangement.elisa`](../../../elisa/d/derangement.elisa) |
| Nim | [`nim/d/derangement.nim`](../../../nim/d/derangement.nim) |
| Odin | [`odin/d/derangement.odin`](../../../odin/d/derangement.odin) |
| Rust | [`rust/d/derangement.rs`](../../../rust/d/derangement.rs) |
| V | [`v/d/derangement.v`](../../../v/d/derangement.v) |
| Zig | [`zig/d/derangement.zig`](../../../zig/d/derangement.zig) |

## Pinned source

- [Python `derangement.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/derangement.py)

The source accepts nonnegative integers below 1560 and uses dynamic programming. This benchmark bounds the input to 20 so its exact result fits the shared signed 64-bit return type.
