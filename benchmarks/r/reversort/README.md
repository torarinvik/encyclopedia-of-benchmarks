# Reversort

This benchmark ports the pinned Python `reversort` routine. At each index, it finds the minimum in the remaining suffix and reverses the range from the current index through that minimum. The input is copied by the timing harness before each call.

The shared sort contract uses signed 64-bit values and array lengths 0, 16, 256, and 1,024. Each port operates in place, uses no processor-specific instructions, and returns the array in ascending order.

The companion [`reversort_cost`](../reversort_cost/README.md) benchmark measures the total length of each reversal, including length-one reversals.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reversort.c`](../../../c/r/reversort.c) |
| C3 | [`c3/r/reversort.c3`](../../../c3/r/reversort.c3) |
| C++ | [`cpp/r/reversort.cpp`](../../../cpp/r/reversort.cpp) |
| Elisa | [`elisa/r/reversort.elisa`](../../../elisa/r/reversort.elisa) |
| Nim | [`nim/r/reversort.nim`](../../../nim/r/reversort.nim) |
| Odin | [`odin/r/reversort.odin`](../../../odin/r/reversort.odin) |
| Rust | [`rust/r/reversort.rs`](../../../rust/r/reversort.rs) |
| V | [`v/r/reversort.v`](../../../v/r/reversort.v) |
| Zig | [`zig/r/reversort.zig`](../../../zig/r/reversort.zig) |

## Pinned source

- Python [`sorts/reversort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/reversort.py)
