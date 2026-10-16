# Reversort Cost

This benchmark ports the pinned Python `reversort_cost` routine. It repeatedly finds the minimum element in the current suffix, reverses through it, and adds the reversed segment length to the total. The routine counts a length-one reversal when the minimum is already at the current index.

The signed-i64-array input is bounded to 256 signed 32-bit values. Empty input costs 0. Valid input returns the accumulated cost; a value outside the signed 32-bit range or an oversized array returns -1. The bounded output fits in signed 64-bit arithmetic.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm reversort_cost --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/r/reversort_cost/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reversort_cost.c`](../../../c/r/reversort_cost.c) |
| C3 | [`c3/r/reversort_cost.c3`](../../../c3/r/reversort_cost.c3) |
| C++ | [`cpp/r/reversort_cost.cpp`](../../../cpp/r/reversort_cost.cpp) |
| Elisa | [`elisa/r/reversort_cost.elisa`](../../../elisa/r/reversort_cost.elisa) |
| Nim | [`nim/r/reversort_cost.nim`](../../../nim/r/reversort_cost.nim) |
| Odin | [`odin/r/reversort_cost.odin`](../../../odin/r/reversort_cost.odin) |
| Rust | [`rust/r/reversort_cost.rs`](../../../rust/r/reversort_cost.rs) |
| V | [`v/r/reversort_cost.v`](../../../v/r/reversort_cost.v) |
| Zig | [`zig/r/reversort_cost.zig`](../../../zig/r/reversort_cost.zig) |

## Pinned source

- Python [`reversort_cost` in `sorts/reversort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/reversort.py)
