# Power by repeated multiplication

The pinned Dart `pow(int a, int b)` initializes a double result to 1 and multiplies by `a` for each integer counter from 1 through `b`. Consequently, `b <= 0` returns 1, including negative exponents; positive powers use repeated multiplication rather than a library exponentiation routine.

## Contract

Input is `[base, exponent]`, with base in `[-1000, 1000]` and exponent in `[-8, 12]`. Output is the resulting float64. Invalid input returns `-1e300`. The exponent bounds keep results finite and the negative-exponent behavior intentionally preserves the source loop’s empty iteration range.

See [`workload.json`](workload.json) and the runtime [oracle](../../pow_oracle.py). Pinned source: [TheAlgorithms/Dart `pow.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/pow.dart).

| Language | Port |
|---|---|
| C | [`c/p/pow.c`](../../../c/p/pow.c) |
| C3 | [`c3/p/pow.c3`](../../../c3/p/pow.c3) |
| C++ | [`cpp/p/pow.cpp`](../../../cpp/p/pow.cpp) |
| Elisa | [`elisa/p/pow.elisa`](../../../elisa/p/pow.elisa) |
| Nim | [`nim/p/pow.nim`](../../../nim/p/pow.nim) |
| Odin | [`odin/p/pow.odin`](../../../odin/p/pow.odin) |
| Rust | [`rust/p/pow.rs`](../../../rust/p/pow.rs) |
| V | [`v/p/pow.v`](../../../v/p/pow.v) |
| Zig | [`zig/p/pow.zig`](../../../zig/p/pow.zig) |
