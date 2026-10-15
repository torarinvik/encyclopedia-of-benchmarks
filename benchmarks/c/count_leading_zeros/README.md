# Count leading zeros

Counts the zero bits before the first set bit in a signed 32-bit integer's two's-complement representation.

## Contract

- Uses the unary scalar ABI: `int64_t count_leading_zeros(int64_t value)`.
- Inputs in `[-2,147,483,648, 2,147,483,647]` are accepted. Values outside this signed 32-bit range return `-1`.
- Returns a count from `0` through `32`. Zero returns `32`; every negative int32 value returns `0` because its top bit is set.
- The count is measured in exactly 32 bits, regardless of the 64-bit ABI type.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `CountLeadingZeros.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/CountLeadingZeros.java). Its input is Java `int`; zero is a special case returning 32. For any other value it scans a mask from bit 31 down until the mask intersects the input. Thus positive values count leading zero bits and negative values return zero. The shared scalar ABI widens inputs to signed 64-bit, so this benchmark explicitly restricts values to the source's int32 domain and returns `-1` for wider values.

## Workload and build

[`workload.json`](workload.json) covers zero, representative positive and negative bit patterns, both int32 limits, and out-of-domain values. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm count_leading_zeros --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/c/count_leading_zeros/c/build.json
```

The nine implementations are in `c/c/count_leading_zeros.c`, `c3/c/count_leading_zeros.c3`, `cpp/c/count_leading_zeros.cpp`, `elisa/c/count_leading_zeros.elisa`, `nim/c/count_leading_zeros.nim`, `odin/c/count_leading_zeros.odin`, `rust/c/count_leading_zeros.rs`, `v/c/count_leading_zeros.v`, and `zig/c/count_leading_zeros.zig`.
