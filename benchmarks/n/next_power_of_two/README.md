# Next power of two

This benchmark returns the smallest power of two greater than or equal to an
input integer.

## Contract

- The unary scalar input is a signed 64-bit integer in `1..=1,073,741,824`.
- Positive powers of two return themselves. Other supported inputs return the
  next larger power of two.
- Inputs outside the supported range return `-1`.

The pinned Python and JavaScript sources agree throughout this positive bounded
domain. Python fills the bits below the highest set bit; JavaScript shifts the
input down while doubling a result, with an early return for exact powers. The
maximum supported value is `2^30`, so both methods return a value that fits the
JavaScript signed 32-bit bitwise operations. Their invalid-input behavior
differs: Python raises for nonpositive values, while JavaScript returns 1
because its loop is skipped. The benchmark excludes those inputs and maps them
to `-1`.

This computes a ceiling power of two, complementary to
[`find_previous_power_of_two`](../../f/find_previous_power_of_two/README.md), which
computes the floor.

## Pinned sources

- [Python `next_power_of_two.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/next_power_of_two.py)
- [JavaScript `NextPowerOfTwo.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/NextPowerOfTwo.js)

## Workload and build

[`workload.json`](workload.json) uses the unary `scalar` ABI and covers invalid
inputs, exact powers, values between powers, and the largest supported value.
Build and record with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm next_power_of_two --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/n/next_power_of_two/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/n/next_power_of_two.c`](../../../c/n/next_power_of_two.c) |
| C3 | [`c3/n/next_power_of_two.c3`](../../../c3/n/next_power_of_two.c3) |
| C++ | [`cpp/n/next_power_of_two.cpp`](../../../cpp/n/next_power_of_two.cpp) |
| Elisa | [`elisa/n/next_power_of_two.elisa`](../../../elisa/n/next_power_of_two.elisa) |
| Nim | [`nim/n/next_power_of_two.nim`](../../../nim/n/next_power_of_two.nim) |
| Odin | [`odin/n/next_power_of_two.odin`](../../../odin/n/next_power_of_two.odin) |
| Rust | [`rust/n/next_power_of_two.rs`](../../../rust/n/next_power_of_two.rs) |
| V | [`v/n/next_power_of_two.v`](../../../v/n/next_power_of_two.v) |
| Zig | [`zig/n/next_power_of_two.zig`](../../../zig/n/next_power_of_two.zig) |
