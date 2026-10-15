# Fletcher-16

Fletcher-16 computes a position-sensitive 16-bit checksum over an ASCII string. The pinned Python source converts the string to ASCII bytes, updates two sums modulo 255 for each byte, then combines them as `(sum2 << 8) | sum1`.

## Contract

- The `i64_array_scalar` input is one ASCII byte value per array element, with no length prefix.
- Accept 0 through 4,096 bytes, each in `[0, 127]`. The empty string returns zero. The bound keeps inputs finite for portable cross-language comparison.
- Return `(sum2 << 8) | sum1`, where `sum1` accumulates each byte modulo 255 and `sum2` accumulates each updated `sum1` modulo 255.
- Invalid lengths or byte values return `-1`. The upstream Python function raises `UnicodeEncodeError` for non-ASCII strings; the benchmark expresses this invalid domain as a sentinel.

The oracle uses the equivalent weighted sum for `sum2`, independently of the per-byte recurrence. The checker covers all ASCII singleton inputs, exhaustive short arrays, deterministic random arrays, modulo-boundary lengths, and invalid inputs across all nine ports.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fletcher16.c`](../../../c/f/fletcher16.c) |
| C3 | [`c3/f/fletcher16.c3`](../../../c3/f/fletcher16.c3) |
| C++ | [`cpp/f/fletcher16.cpp`](../../../cpp/f/fletcher16.cpp) |
| Elisa | [`elisa/f/fletcher16.elisa`](../../../elisa/f/fletcher16.elisa) |
| Nim | [`nim/f/fletcher16.nim`](../../../nim/f/fletcher16.nim) |
| Odin | [`odin/f/fletcher16.odin`](../../../odin/f/fletcher16.odin) |
| Rust | [`rust/f/fletcher16.rs`](../../../rust/f/fletcher16.rs) |
| V | [`v/f/fletcher16.v`](../../../v/f/fletcher16.v) |
| Zig | [`zig/f/fletcher16.zig`](../../../zig/f/fletcher16.zig) |

Upstream sources: [TheAlgorithms/Python `fletcher16.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/fletcher16.py) and [TheAlgorithms/Rust `fletcher.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/fletcher.rs). The Rust implementation is cataloged as an alias because it uses the same recurrence on this benchmark's ASCII domain.

Build with the shared `i64_array_scalar` ABI. Verify all ports with `python3 benchmarks/verify_fletcher16.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.
