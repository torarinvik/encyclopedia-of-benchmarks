# Bifid cipher

Encrypt or decrypt a message with the pinned Python Bifid cipher and its fixed 5x5 Polybius square.

## Contract

- Input is `[mode, text_length, text bytes...]`, with mode `0` for encode and `1` for decode. Text is limited to 256 ASCII bytes.
- The square is `abcdefghiklmnopqrstuvwxyz` in row-major order; `j` shares the `i` cell. This source has no keyword or configurable period: the entire normalized message is one Bifid block.
- Encoding accepts ASCII letters and literal spaces, lowercases the text, removes spaces, and maps `j` to `i`. Output is lowercase ASCII.
- Decoding accepts ASCII letters except `j`, in either case, and lowercases the result. The source calls `message.replace(" ", "")` without assigning its result, so spaces are not removed and cause a lookup error; this contract maps such source errors to `-1`.
- Empty input is valid in either mode. Invalid mode, layout, length, or characters return `-1`; insufficient output capacity returns `-2`. Output bytes have no NUL terminator.

## Algorithm and related benchmarks

For encoding, each plaintext letter becomes a 1-based row/column pair. The cipher concatenates all row numbers followed by all column numbers, then reads adjacent numbers as output coordinates. Decoding performs the inverse reshape and lookup.

This differs from ordinary Polybius substitution, which maps each letter independently, and from Trifid, which uses a 3x3x3 cube and trigraph fractionation. It is also distinct from the existing [Fractionated Morse benchmark](../../f/fractionated_morse_cipher/README.md), which converts Morse trigraphs through a keyed alphabet.

## Workload and implementations

[`workload.json`](workload.json) covers the pinned `testmessage` example in both directions, case and space normalization, `j`/`i` merging, empty input, invalid symbols, malformed input, and the maximum text length.

| Language | Source |
| --- | --- |
| C | [`c/b/bifid_cipher.c`](../../../c/b/bifid_cipher.c) |
| C3 | [`c3/b/bifid_cipher.c3`](../../../c3/b/bifid_cipher.c3) |
| C++ | [`cpp/b/bifid_cipher.cpp`](../../../cpp/b/bifid_cipher.cpp) |
| Elisa | [`elisa/b/bifid_cipher.elisa`](../../../elisa/b/bifid_cipher.elisa) |
| Nim | [`nim/b/bifid_cipher.nim`](../../../nim/b/bifid_cipher.nim) |
| Odin | [`odin/b/bifid_cipher.odin`](../../../odin/b/bifid_cipher.odin) |
| Rust | [`rust/b/bifid_cipher.rs`](../../../rust/b/bifid_cipher.rs) |
| V | [`v/b/bifid_cipher.v`](../../../v/b/bifid_cipher.v) |
| Zig | [`zig/b/bifid_cipher.zig`](../../../zig/b/bifid_cipher.zig) |

## Source

The benchmark follows the pinned [TheAlgorithms/Python `bifid.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/bifid.py). It uses the `i64_array_bytes_output` ABI: `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm bifid_cipher --language c`.
