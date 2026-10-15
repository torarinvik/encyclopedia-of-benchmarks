# Find previous power of two

This benchmark returns the largest power of two less than or equal to its input.

## Contract

- The unary scalar input is a signed 64-bit integer in `0..=2,147,483,647`.
- Input zero returns zero. Every positive input returns the largest power of two
  no greater than that input.
- Negative inputs and values above the pinned Rust source's signed 32-bit range
  return `-1`.
- The implementation preserves the source loop: start at one, double until the
  power exceeds the input, then return the preceding power. Its work is bounded
  to at most 31 doublings.

The pinned Python and Rust implementations agree on this domain. Python rejects
negative inputs and accepts arbitrary-sized integers; Rust accepts signed
32-bit integers and reports negative inputs as errors. The benchmark maps both
invalid cases to `-1`. The output is the power value, distinct from
`highest_set_bit`, which reports a bit position.

## Pinned sources

- [Python `find_previous_power_of_two.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/find_previous_power_of_two.py)
- [Rust `find_previous_power_of_two.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/find_previous_power_of_two.rs)

## Workload and build

[`workload.json`](workload.json) uses the unary `scalar` ABI and includes zero,
one, exact powers, values between powers, the largest supported input, and
out-of-range values. Build and record with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm find_previous_power_of_two --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/f/find_previous_power_of_two/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/f/find_previous_power_of_two.c`](../../../c/f/find_previous_power_of_two.c) |
| C3 | [`c3/f/find_previous_power_of_two.c3`](../../../c3/f/find_previous_power_of_two.c3) |
| C++ | [`cpp/f/find_previous_power_of_two.cpp`](../../../cpp/f/find_previous_power_of_two.cpp) |
| Elisa | [`elisa/f/find_previous_power_of_two.elisa`](../../../elisa/f/find_previous_power_of_two.elisa) |
| Nim | [`nim/f/find_previous_power_of_two.nim`](../../../nim/f/find_previous_power_of_two.nim) |
| Odin | [`odin/f/find_previous_power_of_two.odin`](../../../odin/f/find_previous_power_of_two.odin) |
| Rust | [`rust/f/find_previous_power_of_two.rs`](../../../rust/f/find_previous_power_of_two.rs) |
| V | [`v/f/find_previous_power_of_two.v`](../../../v/f/find_previous_power_of_two.v) |
| Zig | [`zig/f/find_previous_power_of_two.zig`](../../../zig/f/find_previous_power_of_two.zig) |
