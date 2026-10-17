# String hash equality

This package implements the pinned Solidity `StringMatch` contract's `stringMatch()` operation. Its setters populate two stored strings; the benchmark input supplies those two byte strings directly, modeling setter setup before the view call. The source returns true exactly when the Ethereum `keccak256(abi.encodePacked(string))` digests are equal. Strings are arbitrary byte sequences: there is no UTF-8 decoding, case folding, or normalization.

Source: [TheAlgorithms/Solidity `src/Maths/stringMatch.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/stringMatch.sol), commit `08cba51fb38e276062b0c9791d7e0ee494ffa903`.

## Contract

The `i64_array_scalar` input is `[len_a, len_b, bytes_a..., bytes_b...]`. Each length is 0 through 64, each byte value is 0 through 255, and the array length must be exactly `2 + len_a + len_b` (maximum 130 values; 131 is accepted as a parseable malformed length). Return `1` when the two 32-byte Keccak-256 digests match, `0` otherwise, and `-1` for null input, malformed framing, an out-of-range length, or a byte outside 0..255. The workload represents a null pointer with declared length 2 so the ABI can pass the null record without dereferencing it. Empty strings are valid non-null arrays containing `[0, 0]`.

Each message fits in one Keccak sponge block. Ports initialize 25 64-bit lanes to zero, absorb one 136-byte rate block as little-endian lanes, apply Ethereum Keccak padding (`block[len] ^= 0x01` and `block[135] ^= 0x80`), then run all 24 rounds of Keccak-f[1600]. They compare the first four output lanes, which are the 32-byte digest. This uses Ethereum's Keccak suffix `0x01`; standardized SHA3-256 uses a different suffix and is not interchangeable.

The round constants, in hexadecimal, are:

`RC = [`

`0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000, 0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009, 0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x000000008000000a, 0x000000008000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003, 0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a, 0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008`]`

The oracle includes the known vectors Keccak-256(``) = `c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470` and Keccak-256(`abc`) = `4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45`.

The benchmark compares digest values, preserving the source's behavior even in the theoretical case where distinct strings collide. The independent Python Keccak oracle is [string_hash_equality_oracle.py](../../string_hash_equality_oracle.py); [workload.json](workload.json) covers the byte domain, empty and binary values, length boundaries, known equality/inequality outcomes, and malformed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/string_hash_equality.c](../../../c/s/string_hash_equality.c) |
| C3 | [c3/s/string_hash_equality.c3](../../../c3/s/string_hash_equality.c3) |
| C++ | [cpp/s/string_hash_equality.cpp](../../../cpp/s/string_hash_equality.cpp) |
| Elisa | [elisa/s/string_hash_equality.elisa](../../../elisa/s/string_hash_equality.elisa) |
| Nim | [nim/s/string_hash_equality.nim](../../../nim/s/string_hash_equality.nim) |
| Odin | [odin/s/string_hash_equality.odin](../../../odin/s/string_hash_equality.odin) |
| Rust | [rust/s/string_hash_equality.rs](../../../rust/s/string_hash_equality.rs) |
| V | [v/s/string_hash_equality.v](../../../v/s/string_hash_equality.v) |
| Zig | [zig/s/string_hash_equality.zig](../../../zig/s/string_hash_equality.zig) |
