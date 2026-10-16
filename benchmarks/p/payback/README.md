# Payback period

The pinned Rust routine accumulates cash flows in input order and returns the zero-based index of the first flow after which the running total is nonnegative. If the total never reaches zero, it returns `None`.

## Contract

Input is `[count, cash_flow...]`, with 0 through 128 integer-valued cash flows in `[-1,000,000, 1,000,000]`. These values represent whole currency units, a bounded exact subset of the source’s float64 input. Output is the first zero-based index at which cumulative flow is nonnegative, or `-1` if none exists. Invalid ABI input returns `-2`.

See [`workload.json`](workload.json) and the runtime [oracle](../../payback_oracle.py). Pinned source: [TheAlgorithms/Rust `payback.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/payback.rs).

| Language | Port |
|---|---|
| C | [`c/p/payback.c`](../../../c/p/payback.c) |
| C3 | [`c3/p/payback.c3`](../../../c3/p/payback.c3) |
| C++ | [`cpp/p/payback.cpp`](../../../cpp/p/payback.cpp) |
| Elisa | [`elisa/p/payback.elisa`](../../../elisa/p/payback.elisa) |
| Nim | [`nim/p/payback.nim`](../../../nim/p/payback.nim) |
| Odin | [`odin/p/payback.odin`](../../../odin/p/payback.odin) |
| Rust | [`rust/p/payback.rs`](../../../rust/p/payback.rs) |
| V | [`v/p/payback.v`](../../../v/p/payback.v) |
| Zig | [`zig/p/payback.zig`](../../../zig/p/payback.zig) |
