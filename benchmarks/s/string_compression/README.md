# String compression

Compress adjacent equal characters by emitting the character and appending its
decimal run count only when that count exceeds one. This follows the pinned
Java [`StringCompression.compress`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/StringCompression.java).

## Contract

- Input is an array of 0 to 64 ASCII code units, each in 0..127.
- A run emits its byte, followed by its decimal count when repeated. A single
  character is copied without a count. Empty input returns zero bytes.
- The byte domain preserves the source's behavior for digit characters, even
  though outputs such as input `11` become the ambiguous byte string `12`.
- Invalid length or code unit returns -1. Insufficient output capacity returns
  -2 without writing output. A 64-byte workspace covers every valid result.
- The Java method processes UTF-16 code units; this benchmark narrows its input
  domain to ASCII so all nine ports share the same byte-level contract.

This differs from [`run_length_encoding`](../../r/run_length_encoding/README.md),
which writes the count before the character and includes a count for every run.

[`workload.json`](workload.json) covers empty and singleton inputs, repeated
runs, the maximum 64-character run, two-digit counts, digit and NUL bytes, maximum output length, invalid
code units, and insufficient capacity.

Build the Rust port and record its workload with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm string_compression --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/string_compression/rust/build.json
```

Verify all ports and the workload with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm string_compression
```

| Language | Source |
| --- | --- |
| C | [`c/s/string_compression.c`](../../../c/s/string_compression.c) |
| C3 | [`c3/s/string_compression.c3`](../../../c3/s/string_compression.c3) |
| C++ | [`cpp/s/string_compression.cpp`](../../../cpp/s/string_compression.cpp) |
| Elisa | [`elisa/s/string_compression.elisa`](../../../elisa/s/string_compression.elisa) |
| Nim | [`nim/s/string_compression.nim`](../../../nim/s/string_compression.nim) |
| Odin | [`odin/s/string_compression.odin`](../../../odin/s/string_compression.odin) |
| Rust | [`rust/s/string_compression.rs`](../../../rust/s/string_compression.rs) |
| V | [`v/s/string_compression.v`](../../../v/s/string_compression.v) |
| Zig | [`zig/s/string_compression.zig`](../../../zig/s/string_compression.zig) |
