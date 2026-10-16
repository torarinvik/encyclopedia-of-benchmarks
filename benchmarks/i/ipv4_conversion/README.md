# IPv4 conversion

Convert four IPv4 address octets to the unsigned 32-bit decimal value, with the first octet in the most significant byte. This package follows the behavior of the pinned Python and Rust implementations for valid addresses.

## Contract

The `i64_array_scalar` input is exactly `[octet0, octet1, octet2, octet3]`. Every octet must be in `0..255`; malformed lengths and out-of-range octets return `I64_MIN`. For valid input the result is `octet0 * 256^3 + octet1 * 256^2 + octet2 * 256 + octet3`, in the range `0..4,294,967,295`.

The source functions parse exactly four decimal octets, reject octets above 255, and pack them in network byte order. The benchmark interface takes the already parsed octets so it can use the shared scalar-array ABI.

## Sources

- Python [`ipv4_conversion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/ipv4_conversion.py)
- Rust [`ipv4_conversion.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/ipv4_conversion.rs)

## Workload and recording

[`workload.json`](workload.json) covers common private and loopback addresses, zero and maximum addresses, byte boundaries, invalid octets, and malformed lengths. Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm ipv4_conversion --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/ipv4_conversion/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/i/ipv4_conversion.c`](../../../c/i/ipv4_conversion.c) |
| C3 | [`c3/i/ipv4_conversion.c3`](../../../c3/i/ipv4_conversion.c3) |
| C++ | [`cpp/i/ipv4_conversion.cpp`](../../../cpp/i/ipv4_conversion.cpp) |
| Elisa | [`elisa/i/ipv4_conversion.elisa`](../../../elisa/i/ipv4_conversion.elisa) |
| Nim | [`nim/i/ipv4_conversion.nim`](../../../nim/i/ipv4_conversion.nim) |
| Odin | [`odin/i/ipv4_conversion.odin`](../../../odin/i/ipv4_conversion.odin) |
| Rust | [`rust/i/ipv4_conversion.rs`](../../../rust/i/ipv4_conversion.rs) |
| V | [`v/i/ipv4_conversion.v`](../../../v/i/ipv4_conversion.v) |
| Zig | [`zig/i/ipv4_conversion.zig`](../../../zig/i/ipv4_conversion.zig) |
