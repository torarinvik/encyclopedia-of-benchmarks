# IPv4 address validation

Checks whether an ASCII byte string is a canonical dotted-decimal IPv4 address.

## Contract

- Uses the `i64_array_scalar` ABI: `int64_t is_ip_v4_address_valid(const int64_t *bytes, size_t length)`.
- Input is a raw, ordered array of ASCII code points with no terminator, bounded to 0..32 bytes. Values outside ASCII or a length above 32 are malformed packed inputs and return `-1`.
- Return `1` for exactly four decimal octets, each in `[0,255]`; otherwise return `0`.
- Leading zeroes are rejected unless the octet is exactly `0`. Whitespace is not trimmed. Empty input returns `0`.
- The 32-byte cap allows representative malformed addresses while covering every valid address (which is at most 15 bytes).

## Source semantics

The benchmark follows the pinned [TheAlgorithms Python `is_ip_v4_address_valid.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/is_ip_v4_address_valid.py). The function splits on literal dots, requires four parts, checks each part with `str.isdigit()`, parses it as an integer, rejects parts whose decimal rendering changes their length (so leading zeroes fail), and requires each value to be 0..255. It does not strip whitespace; only its command-line wrapper calls `strip()`. The shared contract restricts characters to ASCII so the array ABI has portable byte semantics. Within that domain, the ports preserve the source's parsing rules. Non-ASCII packed values and oversized arrays return `-1` as malformed ABI inputs; ordinary malformed addresses return `0`.

## Workload and build

[`workload.json`](workload.json) covers valid addresses, octet boundaries, leading zeroes, whitespace, malformed separators, and invalid packing. Build and record with the array scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_ip_v4_address_valid --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_ip_v4_address_valid/c/build.json
```

The nine implementations are in `c/i/is_ip_v4_address_valid.c`, `c3/i/is_ip_v4_address_valid.c3`, `cpp/i/is_ip_v4_address_valid.cpp`, `elisa/i/is_ip_v4_address_valid.elisa`, `nim/i/is_ip_v4_address_valid.nim`, `odin/i/is_ip_v4_address_valid.odin`, `rust/i/is_ip_v4_address_valid.rs`, `v/i/is_ip_v4_address_valid.v`, and `zig/i/is_ip_v4_address_valid.zig`.
