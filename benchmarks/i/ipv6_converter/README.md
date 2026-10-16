# IPv4-mapped IPv6 conversion

The pinned Java `IPv6Converter` converts IPv4 literals to the mapped IPv6 form `::ffff:a.b.c.d` and extracts IPv4 from an IPv4-mapped IPv6 address. This benchmark uses raw network-order bytes so conversions remain deterministic and independent of Java's host-name resolver and string formatting.

## Contract

The `i64_array_bytes_output` input is either `[0, 4, ipv4_bytes...]` for IPv4-to-mapped-IPv6 or `[1, 16, ipv6_bytes...]` for extraction. Bytes are 0–255. The mapped prefix is ten zero bytes followed by `ff ff`. The extraction operation accepts only that prefix. Invalid selectors, lengths, bytes, or addresses return `-1`; insufficient output capacity returns `-2`. Operation 0 writes 16 bytes, operation 1 writes the final 4 bytes. Each conversion uses O(1) time and space.

[`workload.json`](workload.json) covers both directions, zero IPv4 bytes, invalid mapped prefixes, malformed lengths, byte bounds, and selectors.

## Pinned source

- [Java `IPv6Converter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/IPv6Converter.java)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/ipv6_converter.c`](../../../c/i/ipv6_converter.c) |
| C3 | [`c3/i/ipv6_converter.c3`](../../../c3/i/ipv6_converter.c3) |
| C++ | [`cpp/i/ipv6_converter.cpp`](../../../cpp/i/ipv6_converter.cpp) |
| Elisa | [`elisa/i/ipv6_converter.elisa`](../../../elisa/i/ipv6_converter.elisa) |
| Nim | [`nim/i/ipv6_converter.nim`](../../../nim/i/ipv6_converter.nim) |
| Odin | [`odin/i/ipv6_converter.odin`](../../../odin/i/ipv6_converter.odin) |
| Rust | [`rust/i/ipv6_converter.rs`](../../../rust/i/ipv6_converter.rs) |
| V | [`v/i/ipv6_converter.v`](../../../v/i/ipv6_converter.v) |
| Zig | [`zig/i/ipv6_converter.zig`](../../../zig/i/ipv6_converter.zig) |
