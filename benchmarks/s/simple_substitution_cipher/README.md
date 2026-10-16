# Simple Substitution Cipher

This benchmark ports the reusable encrypt/decrypt operations from the pinned `simple_substitution_cipher.py` source.

## Contract

- Input is `[mode, key[26], message_length, message_bytes...]`; the exact length is `28 + message_length`.
- `mode=0` encrypts and `mode=1` decrypts. The key must be a permutation of uppercase ASCII `A` through `Z`.
- Message length is 0 through 256 and bytes are ASCII 0 through 127. Letter case and nonletters are preserved.
- A successful call returns the message length and writes exactly that many bytes. Invalid input returns `-1`; a null or short output buffer returns `-2` without writing.
- Random key generation and the interactive CLI are excluded.

The independent oracle is [`simple_substitution_cipher_oracle.py`](../../simple_substitution_cipher_oracle.py). The workload covers the pinned example, inverse transformation, identity key, empty input, invalid keys/modes/bytes, and short capacity.

## Pinned source

[TheAlgorithms/Python `ciphers/simple_substitution_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/simple_substitution_cipher.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Implementations

| Language | Source |
| --- | --- |
| C | [simple_substitution_cipher.c](../../../c/s/simple_substitution_cipher.c) |
| C3 | [simple_substitution_cipher.c3](../../../c3/s/simple_substitution_cipher.c3) |
| C++ | [simple_substitution_cipher.cpp](../../../cpp/s/simple_substitution_cipher.cpp) |
| Elisa | [simple_substitution_cipher.elisa](../../../elisa/s/simple_substitution_cipher.elisa) |
| Nim | [simple_substitution_cipher.nim](../../../nim/s/simple_substitution_cipher.nim) |
| Odin | [simple_substitution_cipher.odin](../../../odin/s/simple_substitution_cipher.odin) |
| Rust | [simple_substitution_cipher.rs](../../../rust/s/simple_substitution_cipher.rs) |
| V | [simple_substitution_cipher.v](../../../v/s/simple_substitution_cipher.v) |
| Zig | [simple_substitution_cipher.zig](../../../zig/s/simple_substitution_cipher.zig) |
