# Binary to Excess-3-style output

This benchmark follows the pinned Python function's actual operation: parse the whole input string as a base-2 integer, add 3 once, then format that integer in base 2 with a minimum width of four characters. The source does not encode each decimal digit separately.

## Contract

- The input is a sequence of ASCII byte values packed as one signed 64-bit value per byte. Text length is from 1 through 128 bytes.
- The accepted ASCII subset follows Python's `int(text, 2)` spelling: binary digits `0` and `1`, optional leading sign, optional `0b` or `0B` prefix, surrounding ASCII whitespace, and single underscores between digits (or one immediately after a base prefix).
- The parsed integer must be in `[-2^62, 2^62]`. This bounded range keeps adding 3 and formatting safe with signed 64-bit intermediates. Python itself accepts arbitrary-size integers and additional Unicode digits/whitespace; those are outside this shared contract.
- The result is the ASCII representation of `parsed + 3` in base 2, with no prefix and a minimum width of four characters. For negative values, the sign counts toward that width, as in Python's format mini-language. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.

The exported function uses the `i64_array_bytes_output` ABI: `values` holds the ASCII codes, and the function writes result bytes into the caller's output buffer. The runner's byte-output oracle uses Python's own `int(text, 2)` and `format(value, "04b")` within the bounded contract.

## Relation to nearby conversions

This differs from [`binary_to_decimal`](../binary_to_decimal/README.md), which returns the parsed integer, and from [`binary_to_octal`](../binary_to_octal/README.md) / [`binary_to_hexadecimal`](../binary_to_hexadecimal/README.md), which express that integer in another radix. The separate `excess_3_code` candidate encodes each decimal digit into its own four-bit Excess-3 nibble and adds a `0b` prefix; it is related by name but is not equivalent to this whole-number `+3` transformation. [`binary_coded_decimal`](../binary_coded_decimal/README.md) likewise packs decimal digits into nibbles and is a different representation.

## Workload and build

[`workload.json`](workload.json) includes the pinned `1010` example, leading zeroes, Python-style signs/prefix/separators/whitespace, minimum-width and negative-format cases, numeric bounds, malformed text, and the text-length bound. Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_to_excess3 --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/binary_to_excess3/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/binary_to_excess3.c`](../../../c/b/binary_to_excess3.c) |
| C3 | [`c3/b/binary_to_excess3.c3`](../../../c3/b/binary_to_excess3.c3) |
| C++ | [`cpp/b/binary_to_excess3.cpp`](../../../cpp/b/binary_to_excess3.cpp) |
| Elisa | [`elisa/b/binary_to_excess3.elisa`](../../../elisa/b/binary_to_excess3.elisa) |
| Nim | [`nim/b/binary_to_excess3.nim`](../../../nim/b/binary_to_excess3.nim) |
| Odin | [`odin/b/binary_to_excess3.odin`](../../../odin/b/binary_to_excess3.odin) |
| Rust | [`rust/b/binary_to_excess3.rs`](../../../rust/b/binary_to_excess3.rs) |
| V | [`v/b/binary_to_excess3.v`](../../../v/b/binary_to_excess3.v) |
| Zig | [`zig/b/binary_to_excess3.zig`](../../../zig/b/binary_to_excess3.zig) |

## Pinned source

- [Python `binary_to_excess3.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_excess3.py)
