# Hamming code encoder

The pinned Python `emitter_converter` places information bits into non-parity positions, computes even parity for the first requested power-of-two positions, and emits the encoded bit string. The benchmark covers that deterministic encoder; the interactive text conversion, decode path, and forced-error demonstration are outside the contract.

## Contract

The `i64_array_bytes_output` input is `[parity_count, data_length, ASCII bit bytes...]`. Parity count is 1–5, data length is 1–32, and data bytes must be ASCII `0` or `1`. The benchmark preserves the pinned emitter's parity-count rejection condition `r + m <= 2^r - (m - 1)` and requires enough positions to place the requested parity bits. It emits the encoded bits in increasing one-based position order, using even parity, and appends NUL. Invalid input returns `-1`; insufficient output capacity returns `-2`.

[`workload.json`](workload.json) includes the pinned source example, multiple parity counts, all-zero/all-one inputs, and rejected parity, bit, and packed-length cases.

## Pinned source

- [Python `hamming_code.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/hamming_code.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hamming_code.c`](../../../c/h/hamming_code.c) |
| C3 | [`c3/h/hamming_code.c3`](../../../c3/h/hamming_code.c3) |
| C++ | [`cpp/h/hamming_code.cpp`](../../../cpp/h/hamming_code.cpp) |
| Elisa | [`elisa/h/hamming_code.elisa`](../../../elisa/h/hamming_code.elisa) |
| Nim | [`nim/h/hamming_code.nim`](../../../nim/h/hamming_code.nim) |
| Odin | [`odin/h/hamming_code.odin`](../../../odin/h/hamming_code.odin) |
| Rust | [`rust/h/hamming_code.rs`](../../../rust/h/hamming_code.rs) |
| V | [`v/h/hamming_code.v`](../../../v/h/hamming_code.v) |
| Zig | [`zig/h/hamming_code.zig`](../../../zig/h/hamming_code.zig) |
