# RC4 encryption

This package ports the pinned Python `encrypt(plaintext, key)` function. It implements the RC4 key scheduling algorithm and byte stream generator, then XORs the generated stream with the plaintext.

## Contract

Input is `[key_length, plaintext_length, key_bytes..., plaintext_bytes...]`. Keys contain 1–256 bytes; plaintexts contain 0–256 bytes; every byte is an integer in `[0, 255]`. The frame length must be exactly `2 + key_length + plaintext_length`; the parser accepts up to 515 values to detect trailing data after a maximum-size frame.

Successful output is the raw ciphertext bytes, without a prefix, and the return value is the number of bytes written. Empty plaintext succeeds with zero bytes, even when the output pointer is null or its capacity is zero. For nonempty plaintext, a null output pointer or capacity below the plaintext length returns `-2` without writing. Malformed input returns `-1`.

The package covers only encryption. The source's decryption wrapper and interactive command-line interface are outside the benchmark contract.

Pinned source: [`rc4.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rc4.py), function `encrypt`.

See [workload](workload.json) and [oracle](../../rc4_oracle.py).

| Language | Port |
|---|---|
| C | [rc4.c](../../../c/r/rc4.c) |
| C3 | [rc4.c3](../../../c3/r/rc4.c3) |
| C++ | [rc4.cpp](../../../cpp/r/rc4.cpp) |
| Elisa | [rc4.elisa](../../../elisa/r/rc4.elisa) |
| Nim | [rc4.nim](../../../nim/r/rc4.nim) |
| Odin | [rc4.odin](../../../odin/r/rc4.odin) |
| Rust | [rc4.rs](../../../rust/r/rc4.rs) |
| V | [rc4.v](../../../v/r/rc4.v) |
| Zig | [rc4.zig](../../../zig/r/rc4.zig) |
