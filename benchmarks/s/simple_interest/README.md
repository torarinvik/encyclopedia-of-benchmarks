# Simple Interest

## Contract

Compute simple interest as `principal * daily_rate * days`. `principal` is in `(0, 1,000,000]`, `daily_rate` is in `[0, 1]`, and `days` is in `(0, 3,650]`. Inputs outside these ranges return `-1e300`. The three inputs and result use binary64 floating point.

The bounded workload keeps every valid result finite. The ports preserve the source operation order and validation requirements while using the same scalar ABI.

## Workload

[`workload.json`](workload.json) covers the pinned source examples, a zero-rate case, and each invalid lower bound.

## TheAlgorithms references

- Python [`financial/interest.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/interest.py) implements `simple_interest` with the same three arguments and multiplication order.
- Rust [`src/financial/interest.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/interest.rs) implements the matching operation and validation conditions.
- Rust [`src/math/interest.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/interest.rs) contains a distinct simple-interest API returning both interest and future value; it is not part of this scalar contract.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/simple_interest.c](../../../c/s/simple_interest.c) |
| C3 | [c3/s/simple_interest.c3](../../../c3/s/simple_interest.c3) |
| C++ | [cpp/s/simple_interest.cpp](../../../cpp/s/simple_interest.cpp) |
| Elisa | [elisa/s/simple_interest.elisa](../../../elisa/s/simple_interest.elisa) |
| Nim | [nim/s/simple_interest.nim](../../../nim/s/simple_interest.nim) |
| Odin | [odin/s/simple_interest.odin](../../../odin/s/simple_interest.odin) |
| Rust | [rust/s/simple_interest.rs](../../../rust/s/simple_interest.rs) |
| V | [v/s/simple_interest.v](../../../v/s/simple_interest.v) |
| Zig | [zig/s/simple_interest.zig](../../../zig/s/simple_interest.zig) |
