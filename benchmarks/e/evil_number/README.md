# Evil number

## Contract

An evil number is a nonnegative integer with an even number of set bits in its
binary representation. The benchmark accepts a signed 64-bit input: negative
values return `-1`; otherwise it returns `1` for an even popcount and `0` for
an odd popcount. Zero is evil because its popcount is zero.

The pinned Java implementation uses a signed 32-bit parameter, while the
Python implementation uses arbitrary-precision integers. The shared signed
64-bit domain extends the same counting rule to values that fit the portable
ABI; the count itself remains bounded by 63. The related `hamming_weight`
benchmark returns the popcount, while this benchmark returns only its parity
classification.

## Workload and build

[`workload.json`](workload.json) covers zero, even and odd popcounts, large
values, the signed maximum, and a negative input. It uses the unary scalar ABI.

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm evil_number --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/e/evil_number/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/e/evil_number.c`](../../../c/e/evil_number.c) |
| C3 | [`c3/e/evil_number.c3`](../../../c3/e/evil_number.c3) |
| C++ | [`cpp/e/evil_number.cpp`](../../../cpp/e/evil_number.cpp) |
| Elisa | [`elisa/e/evil_number.elisa`](../../../elisa/e/evil_number.elisa) |
| Nim | [`nim/e/evil_number.nim`](../../../nim/e/evil_number.nim) |
| Odin | [`odin/e/evil_number.odin`](../../../odin/e/evil_number.odin) |
| Rust | [`rust/e/evil_number.rs`](../../../rust/e/evil_number.rs) |
| V | [`v/e/evil_number.v`](../../../v/e/evil_number.v) |
| Zig | [`zig/e/evil_number.zig`](../../../zig/e/evil_number.zig) |

## Pinned sources

- [Java `EvilNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/EvilNumber.java)
- [Python `evil_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/evil_number.py)
