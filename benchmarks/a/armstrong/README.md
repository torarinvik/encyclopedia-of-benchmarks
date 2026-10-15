# Armstrong number checker

Check whether an integer equals the sum of its decimal digits, each raised to the number of decimal digits. The pinned Java source calls this an Armstrong number and notes that it is also called a Narcissistic number.

## Contract

- Inputs in the signed 32-bit range are accepted, matching the Java `int` parameter. Values outside that range return `-1` in the widened benchmark ABI.
- Negative values return `0`; zero returns `1`; positive values return `1` exactly when the digit-power sum equals the input.
- Results are encoded as `1` for true and `0` for false. The exported ABI entry point is `int64_t armstrong(int64_t number)`.
- The ports count decimal digits by repeated division and use integer powers. The Java source uses `Math.log10` and `Math.pow`; the bounded domain keeps each power and the full sum exactly representable in the source's `long` accumulator.
- Runtime and auxiliary space are constant for the fixed-width input domain.

[`workload.json`](workload.json) covers zero, negative values, source examples, known Armstrong numbers across the Java `int` range, and both signed 32-bit boundaries.

Build and record one port with:

```sh
python3 benchmarks/build_scalar.py --algorithm armstrong --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/a/armstrong/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/a/armstrong.c`](../../../c/a/armstrong.c) |
| C3 | [`c3/a/armstrong.c3`](../../../c3/a/armstrong.c3) |
| C++ | [`cpp/a/armstrong.cpp`](../../../cpp/a/armstrong.cpp) |
| Elisa | [`elisa/a/armstrong.elisa`](../../../elisa/a/armstrong.elisa) |
| Nim | [`nim/a/armstrong.nim`](../../../nim/a/armstrong.nim) |
| Odin | [`odin/a/armstrong.odin`](../../../odin/a/armstrong.odin) |
| Rust | [`rust/a/armstrong.rs`](../../../rust/a/armstrong.rs) |
| V | [`v/a/armstrong.v`](../../../v/a/armstrong.v) |
| Zig | [`zig/a/armstrong.zig`](../../../zig/a/armstrong.zig) |

## Upstream source

- [TheAlgorithms/Java `Armstrong.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Armstrong.java)
