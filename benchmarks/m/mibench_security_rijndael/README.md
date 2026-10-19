# MiBench security-rijndael

This package implements the AES-256 block-encryption kernel selected by the
pinned MiBench Rijndael launcher. The source configures a 16-byte block, accepts
16-, 24-, or 32-byte keys, and the launcher selects encryption with a
64-hex-digit (32-byte) key. The bounded suite exercises the source's
`set_key(..., enc, ...)` and `encrypt` calls for one block.

## Bounded contract

Input is exactly 48 signed-i64 values: the first 32 are key bytes and the final
16 are the block bytes passed to `encrypt`. Every value must be in `0..255`.
Output is the 16 raw AES ciphertext bytes. Invalid input returns `-1`; null or
short output capacity returns `-2` without writes; success returns `16`.

The upstream `aesxam` wrapper encrypts files in CBC mode: it XORs each block
with the prior ciphertext or IV before calling `encrypt`. This package's block
input represents that already-XORed 16-byte state, keeping the measured call
on the source's AES primitive. The file stream, IV generation, and partial
block framing remain outside this kernel contract.

## Pinned source and license

- [`aes.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-rijndael/aes.c): `set_key` and `encrypt`.
- [`aes.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-rijndael/aes.h): the launcher build's `BLOCK_SIZE=16` and little-endian external byte order.
- [`aesxam.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-rijndael/aesxam.c) and [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-rijndael/info.sh): file wrapper and selected launcher arguments.
- [`LICENSE.txt`](LICENSE.txt): Brian Gladman's redistribution conditions and disclaimer, retained with the ports.

The ports use an algebraic AES S-box and round transformations rather than
copying the source's table-driven implementation. [`workload.json`](workload.json)
records the pin and fixed block profile. The independent
[`mibench_security_rijndael_oracle.py`](../../mibench_security_rijndael_oracle.py)
implements the byte-oriented AES-256 round schedule.

| Language | Port |
|---|---|
| C | [`c/m/mibench_security_rijndael.c`](../../../c/mibench_security_rijndael.c) |
| C3 | [`c3/m/mibench_security_rijndael.c3`](../../../c3/m/mibench_security_rijndael.c3) |
| C++ | [`cpp/m/mibench_security_rijndael.cpp`](../../../cpp/m/mibench_security_rijndael.cpp) |
| Elisa | [`elisa/m/mibench_security_rijndael.elisa`](../../../elisa/m/mibench_security_rijndael.elisa) |
| Nim | [`nim/m/mibench_security_rijndael.nim`](../../../nim/m/mibench_security_rijndael.nim) |
| Odin | [`odin/m/mibench_security_rijndael.odin`](../../../odin/m/mibench_security_rijndael.odin) |
| Rust | [`rust/m/mibench_security_rijndael.rs`](../../../rust/m/mibench_security_rijndael.rs) |
| V | [`v/m/mibench_security_rijndael.v`](../../../v/m/mibench_security_rijndael.v) |
| Zig | [`zig/m/mibench_security_rijndael.zig`](../../../zig/m/mibench_security_rijndael.zig) |
