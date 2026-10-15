# Highest set bit

## Contract

The pinned Rust function returns the zero-based index of the most significant
set bit for a positive integer. This benchmark accepts a signed 64-bit input
in `0..=9,223,372,036,854,775,807`. Positive values return
`floor(log2(n))`; zero and negative values return `-1`. Zero has no set bit,
and the negative-input result bounds the operation to the scalar ABI domain.

The pinned Java and Rust implementations both define the positive result as
the zero-based index and represent zero as no value; the benchmark encodes
that missing result as `-1`. Java's source accepts signed 32-bit inputs, while
the Rust source accepts `usize`; the benchmark standardizes on the signed
64-bit ABI's nonnegative range.

The pinned Python implementation reports the bit length instead, which is one
greater than the Rust index for positive inputs; it returns zero for zero. It
also right-shifts negative integers indefinitely, so negative inputs are
excluded from the source algorithm's intended domain and normalized to `-1`.
The contract follows the Rust function's zero-based position convention.

## Workload and build

[`workload.json`](workload.json) covers zero, powers of two, values between
powers of two, the largest signed input, and negative inputs. It uses the
unary `scalar` ABI.

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm highest_set_bit --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/h/highest_set_bit/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/h/highest_set_bit.c`](../../../c/h/highest_set_bit.c) |
| C3 | [`c3/h/highest_set_bit.c3`](../../../c3/h/highest_set_bit.c3) |
| C++ | [`cpp/h/highest_set_bit.cpp`](../../../cpp/h/highest_set_bit.cpp) |
| Elisa | [`elisa/h/highest_set_bit.elisa`](../../../elisa/h/highest_set_bit.elisa) |
| Nim | [`nim/h/highest_set_bit.nim`](../../../nim/h/highest_set_bit.nim) |
| Odin | [`odin/h/highest_set_bit.odin`](../../../odin/h/highest_set_bit.odin) |
| Rust | [`rust/h/highest_set_bit.rs`](../../../rust/h/highest_set_bit.rs) |
| V | [`v/h/highest_set_bit.v`](../../../v/h/highest_set_bit.v) |
| Zig | [`zig/h/highest_set_bit.zig`](../../../zig/h/highest_set_bit.zig) |

## Pinned sources

- [Java `HighestSetBit.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/HighestSetBit.java)
- [Rust `highest_set_bit.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/highest_set_bit.rs)
- [Python `highest_set_bit.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/highest_set_bit.py)
