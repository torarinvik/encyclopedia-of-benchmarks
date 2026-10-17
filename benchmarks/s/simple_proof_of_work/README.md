# Simple proof of work

Find the first nonce whose SHA-256 digest has the requested lowercase
hexadecimal zero prefix, following the pinned Python `proof_of_work` routine.
The benchmark adds a bounded nonce cap so every call has finite work.

## Contract

- Input is a signed 64-bit array `[block_number, difficulty, max_nonce,
  transactions_length, previous_hash_length, transactions_ascii...,
  previous_hash_ascii...]`. The exact packed length is
  `5 + transactions_length + previous_hash_length`.
- `block_number` is 0..`INT64_MAX`, difficulty is 0..2, and `max_nonce` is
  0..4096 inclusive. Search nonce values from 0 through `max_nonce`, inclusive,
  in order. Difficulty 0 therefore succeeds immediately at nonce 0.
- Each text field is 0..64 ASCII code units. Codes 0..127 are accepted; explicit
  lengths preserve embedded NUL bytes. Decode these bytes as ASCII, then hash
  the exact delimiter-free UTF-8 encoding of
  `f"{block_number}{transactions}{previous_hash}{nonce}"` with SHA-256. Compare
  the lowercase hexadecimal digest against the requested zero prefix.
- On success, output 8-byte little-endian nonce followed by the 64 lowercase
  ASCII digest characters (72 bytes total). Return 72.
- Null or malformed input returns `-1`; null or insufficient output returns
  `-2`; an exhausted nonce range returns `-3`. Validate input first, then output
  availability, then search. Errors write no output. The maximum valid input is
  133 words; 134 words are parseable for malformed-input coverage.

## Workload and oracle

[`workload.json`](workload.json) covers difficulty 0, first and later matching
nonces, the inclusive nonce cap, exhaustion, maximum fields, malformed framing,
invalid ASCII and parameters, null pointers, and output-capacity precedence. The
independent oracle is
[`benchmarks/simple_proof_of_work_oracle.py`](../../simple_proof_of_work_oracle.py).

## Reviewed source

[TheAlgorithms/Python `blockchain/simple_proof_of_work.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/blockchain/simple_proof_of_work.py)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm simple_proof_of_work --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm simple_proof_of_work
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm simple_proof_of_work
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/simple_proof_of_work.c`](../../../c/s/simple_proof_of_work.c) |
| C3 | [`c3/s/simple_proof_of_work.c3`](../../../c3/s/simple_proof_of_work.c3) |
| C++ | [`cpp/s/simple_proof_of_work.cpp`](../../../cpp/s/simple_proof_of_work.cpp) |
| Elisa | [`elisa/s/simple_proof_of_work.elisa`](../../../elisa/s/simple_proof_of_work.elisa) |
| Nim | [`nim/s/simple_proof_of_work.nim`](../../../nim/s/simple_proof_of_work.nim) |
| Odin | [`odin/s/simple_proof_of_work.odin`](../../../odin/s/simple_proof_of_work.odin) |
| Rust | [`rust/s/simple_proof_of_work.rs`](../../../rust/s/simple_proof_of_work.rs) |
| V | [`v/s/simple_proof_of_work.v`](../../../v/s/simple_proof_of_work.v) |
| Zig | [`zig/s/simple_proof_of_work.zig`](../../../zig/s/simple_proof_of_work.zig) |
