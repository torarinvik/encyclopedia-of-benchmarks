# Move-to-front transform

This package follows the pinned Java `MoveToFront.transform` and `inverseTransform` APIs. The mode-tagged ABI measures both directions while preserving the Java methods' shared move-to-front state rule.

## Contract

- Input is `[mode, alphabet_length, payload_length, alphabet_bytes..., payload...]`. Mode `0` encodes text symbols as their current alphabet positions; mode `1` decodes positions to symbols. The alphabet has at most 32 unique ASCII values (`0..127`), and payload length is at most 128.
- For mode `0`, every payload value must be ASCII and present in the alphabet. For mode `1` with a nonempty alphabet, each payload value must be an in-range alphabet index. Invalid shape or values return `-1`.
- The alphabet starts in the provided order. Each symbol is emitted as its current position, then moved to the front. The inverse emits the symbol at each supplied position and makes the same state update.
- Empty payloads produce empty output, including with an empty alphabet. Java's inverse returns an empty string immediately for an empty alphabet even if its index collection is nonempty; this bounded adapter preserves that behavior. Nonempty encoding with an empty alphabet is invalid.
- Output is a byte sequence: one index byte per encoded symbol, or one ASCII byte per decoded symbol. Capacity below the output length returns `-2`; success returns the number of bytes written. A 128-byte workspace covers every valid output.
- Unique alphabet symbols are part of this bounded domain. The pinned Python version explicitly validates uniqueness; Java documents it as a requirement but does not enforce it. The Rust version instead uses a fixed 256-byte alphabet and silently skips unsupported encode characters, so its API is a distinct variant rather than the contract used here.

## Workload and source

[`workload.json`](workload.json) covers the Java example, both Python examples, repeated symbols, decode, empty cases, the empty-alphabet inverse behavior, invalid inputs, and output-capacity boundaries. The independent oracle is [`benchmarks/move_to_front_oracle.py`](../../move_to_front_oracle.py).

Pinned Java source: [TheAlgorithms/Java `MoveToFront.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/MoveToFront.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

Related implementations: [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/move_to_front.py) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/compression/move_to_front.rs).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm move_to_front --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm move_to_front
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/move_to_front.c`](../../../c/m/move_to_front.c) |
| C3 | [`c3/m/move_to_front.c3`](../../../c3/m/move_to_front.c3) |
| C++ | [`cpp/m/move_to_front.cpp`](../../../cpp/m/move_to_front.cpp) |
| Elisa | [`elisa/m/move_to_front.elisa`](../../../elisa/m/move_to_front.elisa) |
| Nim | [`nim/m/move_to_front.nim`](../../../nim/m/move_to_front.nim) |
| Odin | [`odin/m/move_to_front.odin`](../../../odin/m/move_to_front.odin) |
| Rust | [`rust/m/move_to_front.rs`](../../../rust/m/move_to_front.rs) |
| V | [`v/m/move_to_front.v`](../../../v/m/move_to_front.v) |
| Zig | [`zig/m/move_to_front.zig`](../../../zig/m/move_to_front.zig) |
