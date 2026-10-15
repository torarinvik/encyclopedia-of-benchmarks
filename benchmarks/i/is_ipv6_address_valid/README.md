# IPv6 address validity

Check whether a bounded ASCII string is a valid IPv6 address under the rules implemented by the pinned Python source.

## Contract

The `i64_array_scalar` input is `[length, ASCII code points...]`. The declared length must be 0 through 256, the packed array must contain exactly `length + 1` values, and every character code must be in `[0, 127]`. Return `1` for a valid address and `0` for invalid address text. Malformed packed input or a non-ASCII code point returns `-1`.

Groups contain 1 through 4 ASCII hexadecimal digits. An uncompressed address has exactly eight groups. One `::` may compress one or more groups, so a compressed address must have fewer than eight explicit groups. A leading or trailing single colon, repeated compression, `:::`, non-hex group text, and IPv4-mapped endings are invalid. The maximum address-text length accepted by the ABI is 256; valid IPv6 spellings fit within 39 characters.

The bounded contract preserves the source's implemented IPv6 subset: hexadecimal groups in either case, full eight-group spelling, or one `::` compression. The source does not support IPv4-embedded endings.

## Source

The pinned Python [`is_ipv6_address_valid.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/is_ipv6_address_valid.py) checks group widths, count, and compression directly. This package ports that parser over ASCII code points and defines explicit packed-input errors.

## Workload and recording

[`workload.json`](workload.json) covers full and compressed addresses, boundary group counts, uppercase hexadecimal, malformed compression, invalid groups, IPv4-mapped text, empty input, and malformed packed input.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_ipv6_address_valid --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_ipv6_address_valid/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/i/is_ipv6_address_valid.c`](../../../c/i/is_ipv6_address_valid.c) |
| C3 | [`c3/i/is_ipv6_address_valid.c3`](../../../c3/i/is_ipv6_address_valid.c3) |
| C++ | [`cpp/i/is_ipv6_address_valid.cpp`](../../../cpp/i/is_ipv6_address_valid.cpp) |
| Elisa | [`elisa/i/is_ipv6_address_valid.elisa`](../../../elisa/i/is_ipv6_address_valid.elisa) |
| Nim | [`nim/i/is_ipv6_address_valid.nim`](../../../nim/i/is_ipv6_address_valid.nim) |
| Odin | [`odin/i/is_ipv6_address_valid.odin`](../../../odin/i/is_ipv6_address_valid.odin) |
| Rust | [`rust/i/is_ipv6_address_valid.rs`](../../../rust/i/is_ipv6_address_valid.rs) |
| V | [`v/i/is_ipv6_address_valid.v`](../../../v/i/is_ipv6_address_valid.v) |
| Zig | [`zig/i/is_ipv6_address_valid.zig`](../../../zig/i/is_ipv6_address_valid.zig) |
