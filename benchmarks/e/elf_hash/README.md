# ELF hash

Compute the ELF hash of a bounded sequence of ASCII codepoints using the pinned Python algorithm.

## Contract

- ABI: `i64_array_scalar`. Each input array element is one Unicode codepoint; this benchmark accepts the bounded ASCII domain `0..=127`, including NUL as an ordinary codepoint.
- Valid inputs contain 0 through 8 codepoints. The empty string returns `0`; inputs longer than 8 codepoints or containing a value outside the ASCII range return `-1`.
- For each codepoint, update `hash = (hash << 4) + codepoint`, set `high = hash & 0xF0000000`, XOR `high >> 24` when it is nonzero, then clear the bits in `high`. Return the resulting nonnegative integer. The native ports clear `high` by XORing it because it is a subset of `hash`; this preserves bits above bit 31 as the Python source does.
- With codepoints at most 127, the first six un-folded steps stay below `2^28`. Step seven's pre-fold value is at most 2,272,753,519, below `2^32`, so its result is below `2^28`. Step eight's pre-fold value is at most `2^32 + 111`; the high-nibble fold leaves the result below `2^33`, which fits in signed i64. The workload includes seven codepoints `15` followed by `16`, which produces `2^32` and checks preservation of bit 32.

## Source and workload

This follows [TheAlgorithms/Python `elf.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/elf.py). Its example `lorem ipsum` has eleven codepoints, so this benchmark uses an eight-codepoint bound for a small, fixed workload. The source's Python string supports NUL and the empty string, both covered here.

[`workload.json`](workload.json) covers the empty input, NUL, source-derived text, ASCII boundaries, the maximum valid length, invalid codepoints, and one over-bound input.

Build and record Rust with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm elf_hash --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/e/elf_hash/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms elf_hash --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/elf_hash.c`](../../../c/e/elf_hash.c) |
| C3 | [`c3/e/elf_hash.c3`](../../../c3/e/elf_hash.c3) |
| C++ | [`cpp/e/elf_hash.cpp`](../../../cpp/e/elf_hash.cpp) |
| Elisa | [`elisa/e/elf_hash.elisa`](../../../elisa/e/elf_hash.elisa) |
| Nim | [`nim/e/elf_hash.nim`](../../../nim/e/elf_hash.nim) |
| Odin | [`odin/e/elf_hash.odin`](../../../odin/e/elf_hash.odin) |
| Rust | [`rust/e/elf_hash.rs`](../../../rust/e/elf_hash.rs) |
| V | [`v/e/elf_hash.v`](../../../v/e/elf_hash.v) |
| Zig | [`zig/e/elf_hash.zig`](../../../zig/e/elf_hash.zig) |
