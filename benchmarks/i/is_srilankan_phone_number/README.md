# Sri Lankan phone number

Checks an ASCII phone number against the pinned Sri Lankan mobile-number pattern.

## Contract

- Uses the `i64_array_scalar` ABI. Each array element is one ASCII byte value, and the array is the complete phone string.
- Lengths from 1 through 15 are accepted. Matching strings return `1`; nonmatching ASCII strings return `0`.
- Empty or oversized input, a null pointer, or an element outside ASCII `[0, 127]` returns `-1`.
- A match has prefix `0`, `94`, `+94`, or `0094`, followed by `7` and one provider digit from `0, 1, 2, 4, 5, 6, 7, 8`, an optional single hyphen or space, and exactly seven ASCII digits.

## Source semantics

The benchmark follows pinned [TheAlgorithms Python `is_srilankan_phone_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_srilankan_phone_number.py). Its anchored regular expression accepts exactly the prefixes and suffix form above; although it calls `re.search`, the beginning and ending anchors require the entire string to match. Python's `$` anchor also permits one final line feed after the seven digits, which the ports preserve. The source's `\d` also matches some Unicode decimal digits. This portable contract restricts input bytes to ASCII, so non-ASCII values map to `-1` and only ASCII digits match.

## Workload and build

[`workload.json`](workload.json) covers each accepted prefix, optional separators, representative malformed strings, and invalid array domains. Build and record with the array-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_srilankan_phone_number --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_srilankan_phone_number/c/build.json
```

The nine implementations are in `c/i/is_srilankan_phone_number.c`, `c3/i/is_srilankan_phone_number.c3`, `cpp/i/is_srilankan_phone_number.cpp`, `elisa/i/is_srilankan_phone_number.elisa`, `nim/i/is_srilankan_phone_number.nim`, `odin/i/is_srilankan_phone_number.odin`, `rust/i/is_srilankan_phone_number.rs`, `v/i/is_srilankan_phone_number.v`, and `zig/i/is_srilankan_phone_number.zig`.
