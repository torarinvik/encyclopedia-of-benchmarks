# Proof of Work

This package benchmarks the nonce search in the pinned Python blockchain implementation. It freezes the genesis-block fields so every call is deterministic and bounds the source's otherwise unbounded search.

## Contract

The `i64_array_bytes_output` input is exactly `[difficulty, max_nonce]`, where `difficulty` is `0..8` and `max_nonce` is `0..65,535`. Both bounds are inclusive. The block fields are fixed to `index=0`, `previous_hash="0"`, `transactions="Genesis Block"`, and `timestamp=0.0`; they are not part of the input.

For each nonce from zero through `max_nonce`, in ascending order, form the source's delimiter-free string `f"{index}{previous_hash}{transactions}{timestamp}{nonce}"`. With the frozen fields, its ASCII bytes are `00Genesis Block0.0{nonce}`. Hash those bytes with SHA-256 and compare the first `difficulty` lowercase hexadecimal digits with that many zeroes. Difficulty zero succeeds at nonce zero.

On the first match, write 40 bytes: the nonce as a signed little-endian i64, followed by the 32 raw SHA-256 digest bytes. Return 40. If the inclusive nonce range is exhausted, return 0 and write no bytes. Malformed input or values outside the stated ranges return `-1`. If a match exists but the output pointer is null or its capacity is less than 40, return `-2` without writing. A null output is allowed when the search finds no match because that result writes no bytes.

The benchmark covers only block hashing and nonce search. It omits wall-clock timestamps, chain mutation/validation, and printing from the source demo.

## Pinned source

[TheAlgorithms/Python `blockchain/proof_of_work.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/blockchain/proof_of_work.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/proof_of_work.c`](../../../c/p/proof_of_work.c) |
| C3 | [`c3/p/proof_of_work.c3`](../../../c3/p/proof_of_work.c3) |
| C++ | [`cpp/p/proof_of_work.cpp`](../../../cpp/p/proof_of_work.cpp) |
| Elisa | [`elisa/p/proof_of_work.elisa`](../../../elisa/p/proof_of_work.elisa) |
| Nim | [`nim/p/proof_of_work.nim`](../../../nim/p/proof_of_work.nim) |
| Odin | [`odin/p/proof_of_work.odin`](../../../odin/p/proof_of_work.odin) |
| Rust | [`rust/p/proof_of_work.rs`](../../../rust/p/proof_of_work.rs) |
| V | [`v/p/proof_of_work.v`](../../../v/p/proof_of_work.v) |
| Zig | [`zig/p/proof_of_work.zig`](../../../zig/p/proof_of_work.zig) |
