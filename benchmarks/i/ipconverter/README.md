# IPv4 text and binary conversion

Convert dotted IPv4 decimal text to four dotted 8-bit binary groups, or convert four dotted 8-bit binary groups back to dotted decimal text. This follows the two conversion methods in the pinned Java `IPConverter` class.

## Contract

- Valid input is a packed signed-i64 array `[mode, payload_length, ASCII bytes...]` with at most 37 values; the parser admits 38 to exercise the first rejected packed length. Mode 0 converts dotted decimal to dotted binary, and mode 1 converts dotted binary to dotted decimal.
- Mode 0 accepts four decimal groups of one to three digits, each in `0..255`, separated by three dots. Leading zeroes are accepted, matching Java integer parsing.
- Mode 1 accepts exactly four groups of eight `0`/`1` digits, separated by three dots.
- Mode 0 returns 35 bytes (`8 bits`.`8 bits`.`8 bits`.`8 bits`); mode 1 returns canonical dotted decimal text. Output is not NUL-terminated.
- A null input pointer or invalid mode, layout, value, or length returns `-1`. Insufficient output capacity or a null output pointer returns `-2`. The workspace holds 35 bytes.

The source methods parse strings and construct strings. This bounded contract represents input and output text as ASCII byte values and restricts binary groups to exactly eight bits.

## Workload and oracle

[`workload.json`](workload.json) covers both directions, source examples, zero and maximum octets, leading zeroes, malformed headers and groups, and insufficient capacity. The independent oracle is [`ipconverter_oracle.py`](../../ipconverter_oracle.py).

Pinned source: [TheAlgorithms/Java `IPConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/IPConverter.java).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm ipconverter --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm ipconverter
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm ipconverter
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/ipconverter.c`](../../../c/i/ipconverter.c) |
| C3 | [`c3/i/ipconverter.c3`](../../../c3/i/ipconverter.c3) |
| C++ | [`cpp/i/ipconverter.cpp`](../../../cpp/i/ipconverter.cpp) |
| Elisa | [`elisa/i/ipconverter.elisa`](../../../elisa/i/ipconverter.elisa) |
| Nim | [`nim/i/ipconverter.nim`](../../../nim/i/ipconverter.nim) |
| Odin | [`odin/i/ipconverter.odin`](../../../odin/i/ipconverter.odin) |
| Rust | [`rust/i/ipconverter.rs`](../../../rust/i/ipconverter.rs) |
| V | [`v/i/ipconverter.v`](../../../v/i/ipconverter.v) |
| Zig | [`zig/i/ipconverter.zig`](../../../zig/i/ipconverter.zig) |
