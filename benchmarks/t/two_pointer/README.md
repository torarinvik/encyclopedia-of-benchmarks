# Two-pointer two-sum

Find a target sum in a sorted signed-32-bit array by starting at both ends and moving the pointer whose value must change to approach the target.

## Contract

- Input is `[n, target, value_0, ..., value_(n-1)]`; `n` is 0 through 256, all numbers fit signed 32-bit, and values are non-decreasing.
- The scan starts at indices 0 and n-1. It returns immediately on equality, advances the left index when the sum is too small, and decreases the right index when the sum is too large.
- A found pair is encoded as `left_index * 256 + right_index`. Return `-1` when no pair exists and `-2` for malformed input.
- This deterministic contract retains the source scan behavior even when there are multiple solutions; it does not rely on the source prose's exactly-one-solution assumption.

[`workload.json`](workload.json) covers endpoint/interior matches, duplicates, no match, empty input, and unsorted rejection. The runtime oracle is [`two_pointer_oracle.py`](../../two_pointer_oracle.py).

## Pinned source

- [Python `two_pointer.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/two_pointer.py)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm two_pointer --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/t/two_pointer/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/two_pointer.c`](../../../c/t/two_pointer.c) |
| C3 | [`c3/t/two_pointer.c3`](../../../c3/t/two_pointer.c3) |
| C++ | [`cpp/t/two_pointer.cpp`](../../../cpp/t/two_pointer.cpp) |
| Elisa | [`elisa/t/two_pointer.elisa`](../../../elisa/t/two_pointer.elisa) |
| Nim | [`nim/t/two_pointer.nim`](../../../nim/t/two_pointer.nim) |
| Odin | [`odin/t/two_pointer.odin`](../../../odin/t/two_pointer.odin) |
| Rust | [`rust/t/two_pointer.rs`](../../../rust/t/two_pointer.rs) |
| V | [`v/t/two_pointer.v`](../../../v/t/two_pointer.v) |
| Zig | [`zig/t/two_pointer.zig`](../../../zig/t/two_pointer.zig) |
