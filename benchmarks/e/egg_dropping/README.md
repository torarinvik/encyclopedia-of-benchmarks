# Egg dropping

Compute the minimum number of egg drops needed in the worst case to identify the highest safe floor. The package follows the bottom-up dynamic-programming recurrence shared by the pinned Java, Python, and Rust implementations.

## Contract

The `i64_array_scalar` input is exactly `[eggs, floors]`, with `eggs` in `1..12` and `floors` in `1..128`. The result is the minimum worst-case number of drops. A malformed array or a value outside those bounds returns `I64_MIN`.

The domain requires at least one floor. The Java source initializes the one-floor DP column unconditionally, so its implementation is not safe for zero floors. Zero eggs is also excluded: Rust returns `None`; Python returns the floor count for zero or one floor but fails while initializing row 1 for larger floor counts; Java returns `0` at zero floors but indexes outside its table for positive floors. The ABI normalizes zero eggs to the invalid-input sentinel.

For each egg count `e` and floor count `f`, the recurrence tries each first drop `x` and minimizes `1 + max(dp[e-1][x-1], dp[e][f-x])`. The bounded domain keeps the dynamic-programming table and result within signed 64-bit range.

## Sources

- Java [`EggDropping.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/EggDropping.java)
- Python [`egg_dropping.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/egg_dropping.py)
- Rust [`egg_dropping.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/egg_dropping.rs)

## Workload and recording

[`workload.json`](workload.json) includes the pinned examples, one-egg and one-floor boundaries, larger two-egg and multi-egg cases, and malformed inputs. Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm egg_dropping --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/e/egg_dropping/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/e/egg_dropping.c`](../../../c/e/egg_dropping.c) |
| C3 | [`c3/e/egg_dropping.c3`](../../../c3/e/egg_dropping.c3) |
| C++ | [`cpp/e/egg_dropping.cpp`](../../../cpp/e/egg_dropping.cpp) |
| Elisa | [`elisa/e/egg_dropping.elisa`](../../../elisa/e/egg_dropping.elisa) |
| Nim | [`nim/e/egg_dropping.nim`](../../../nim/e/egg_dropping.nim) |
| Odin | [`odin/e/egg_dropping.odin`](../../../odin/e/egg_dropping.odin) |
| Rust | [`rust/e/egg_dropping.rs`](../../../rust/e/egg_dropping.rs) |
| V | [`v/e/egg_dropping.v`](../../../v/e/egg_dropping.v) |
| Zig | [`zig/e/egg_dropping.zig`](../../../zig/e/egg_dropping.zig) |
