# Trifid cipher

Encrypt or decrypt ASCII text with the pinned Python Trifid cipher, a 3×3×3 cube cipher that fractionates each block into three coordinate streams.

## Contract

Input is `[mode, period, text_length, alphabet_length, text bytes..., alphabet bytes...]`. Mode `0` encrypts and mode `1` decrypts. Text is at most 256 ASCII bytes, period is from 1 through 256, and the alphabet has exactly 27 distinct symbols after removing spaces and uppercasing. The message is uppercased and spaces are removed. Each remaining message character must occur in the alphabet. Output contains the resulting alphabet symbols as ASCII with no NUL terminator. Invalid input returns `-1`; insufficient output capacity returns `-2`.

## Algorithm

The alphabet's 27 symbols correspond in order to the `111` through `333` coordinate triples. Encryption handles each period-sized block separately: it writes all first coordinates, then all second coordinates, then all third coordinates, and decodes each resulting triple through the same alphabet. Decryption concatenates each ciphertext symbol's triple, splits the coordinates into three equal streams, and interleaves them back into plaintext triples. The final block may be shorter than the period.

This is distinct from [Bifid](../../b/bifid_cipher/README.md): Trifid uses a 3×3×3 cube, a 27-symbol alphabet, and periodic blocks; Bifid uses a 5×5 square, merges `j` into `i`, and treats the whole message as one block.

## Workload and implementations

[`workload.json`](workload.json) covers the pinned examples, custom alphabet, normalization, periods, empty text, invalid input, and output capacity.

| Language | Source |
| --- | --- |
| C | [`c/t/trifid_cipher.c`](../../../c/t/trifid_cipher.c) |
| C3 | [`c3/t/trifid_cipher.c3`](../../../c3/t/trifid_cipher.c3) |
| C++ | [`cpp/t/trifid_cipher.cpp`](../../../cpp/t/trifid_cipher.cpp) |
| Elisa | [`elisa/t/trifid_cipher.elisa`](../../../elisa/t/trifid_cipher.elisa) |
| Nim | [`nim/t/trifid_cipher.nim`](../../../nim/t/trifid_cipher.nim) |
| Odin | [`odin/t/trifid_cipher.odin`](../../../odin/t/trifid_cipher.odin) |
| Rust | [`rust/t/trifid_cipher.rs`](../../../rust/t/trifid_cipher.rs) |
| V | [`v/t/trifid_cipher.v`](../../../v/t/trifid_cipher.v) |
| Zig | [`zig/t/trifid_cipher.zig`](../../../zig/t/trifid_cipher.zig) |

## Source

The reference is the pinned [TheAlgorithms/Python `trifid_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/trifid_cipher.py). Build with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm trifid_cipher --language c`.
