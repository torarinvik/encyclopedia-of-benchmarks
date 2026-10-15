# Index of rightmost set bit

Returns the zero-based index of the least significant set bit in the magnitude of a signed 32-bit input.

## Contract

- Uses the `scalar` ABI with one signed integer input.
- Valid inputs fit signed 32-bit range.
- Returns `-1` for zero, which has no set bits, and for inputs outside signed 32-bit range.
- For any other input, returns the zero-based bit index from 0 through 31. Negative values follow the pinned Java method's negate-then-isolate behavior; `INT32_MIN` returns 31.

## Source semantics

This follows pinned [TheAlgorithms Java `IndexOfRightMostSetBit.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/IndexOfRightMostSetBit.java). For a negative value, Java negates the signed `int` and isolates its lowest set bit with `n & (~n + 1)`, then counts right shifts from zero. Negating `INT32_MIN` wraps to itself in Java; isolating that bit still produces the high bit and returns index 31. The ports widen the accepted int32 value for magnitude calculation, which gives the same result, including at that boundary.

The Python sibling `index_of_rightmost_set_bit` also returns a zero-based index for nonnegative inputs, but rejects negative values; it maps to this benchmark on the shared positive-input subset. The Rust `rightmost_set_bit` source instead returns a one-based position and only accepts positive inputs, so that remains a separate operation.

## Workload and build

[`workload.json`](workload.json) covers zero, both signs, `INT32_MIN`, `INT32_MAX`, and invalid ABI values. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm index_of_right_most_set_bit --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/i/index_of_right_most_set_bit/rust/build.json
```

The nine implementations are in `c/i/index_of_right_most_set_bit.c`, `c3/i/index_of_right_most_set_bit.c3`, `cpp/i/index_of_right_most_set_bit.cpp`, `elisa/i/index_of_right_most_set_bit.elisa`, `nim/i/index_of_right_most_set_bit.nim`, `odin/i/index_of_right_most_set_bit.odin`, `rust/i/index_of_right_most_set_bit.rs`, `v/i/index_of_right_most_set_bit.v`, and `zig/i/index_of_right_most_set_bit.zig`.
