# Bitap Exact Match (31-bit)

This package ports the pinned C# Bitap exact matcher. It preserves the source's 31-character pattern limit and returns the first matching byte offset. The 31-bit pattern bound fits the source algorithm's signed 32-bit state while keeping the shift at bit 31 defined through unsigned 32-bit arithmetic in these ports.

## Contract

Input is a signed 64-bit array `[text_length, pattern_length, text bytes..., pattern bytes...]`. Text length is 0 to 4,096 bytes and pattern length is 0 to 31 bytes. Both text and pattern use lowercase ASCII `a` through `z`, and the input length must equal `2 + text_length + pattern_length`. An empty pattern returns 0; a nonempty pattern longer than the text or absent from the text returns -1. Malformed inputs return -2. The source throws for pattern lengths above 31; the ABI wrapper represents that invalid input with -2.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm bitap_exact_match_31 --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/bitap_exact_match_31/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bitap_exact_match_31.c`](../../../c/b/bitap_exact_match_31.c) |
| C3 | [`c3/b/bitap_exact_match_31.c3`](../../../c3/b/bitap_exact_match_31.c3) |
| C++ | [`cpp/b/bitap_exact_match_31.cpp`](../../../cpp/b/bitap_exact_match_31.cpp) |
| Elisa | [`elisa/b/bitap_exact_match_31.elisa`](../../../elisa/b/bitap_exact_match_31.elisa) |
| Nim | [`nim/b/bitap_exact_match_31.nim`](../../../nim/b/bitap_exact_match_31.nim) |
| Odin | [`odin/b/bitap_exact_match_31.odin`](../../../odin/b/bitap_exact_match_31.odin) |
| Rust | [`rust/b/bitap_exact_match_31.rs`](../../../rust/b/bitap_exact_match_31.rs) |
| V | [`v/b/bitap_exact_match_31.v`](../../../v/b/bitap_exact_match_31.v) |
| Zig | [`zig/b/bitap_exact_match_31.zig`](../../../zig/b/bitap_exact_match_31.zig) |

## Pinned source

- C# [`Bitap.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/PatternMatching/Bitap.cs)
