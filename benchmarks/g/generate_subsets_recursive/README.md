# Recursive string subsets

## Contract

This benchmark follows the Java recursive `GenerateSubsets.subsetRecursion` traversal. At each character it explores the include branch first, then the exclude branch. The emitted subsets therefore preserve character order and use depth-first include-first order: `ab` yields `ab`, `a`, `b`, then the empty string. Repeated characters are separate positions and can produce identical subset strings.

Input is `[length, ASCII byte values...]`, with `length` from 0 through 12 and exactly that many values in the inclusive range 0..127. The bounded ASCII domain preserves the source's character-level behavior while giving all targets the same byte encoding.

Output is binary: a little-endian u32 subset count followed by each subset as a little-endian u32 byte length and its bytes. This length prefix keeps empty subsets and embedded NUL bytes unambiguous. The function returns the number of bytes written, `-1` for malformed input, and `-2` when output capacity is too small. The maximum workspace is 40,960 bytes.

[`workload.json`](workload.json) records empty, singleton, ordering, duplicate-character, NUL-byte, malformed, and capacity-boundary cases. The independent oracle is [`benchmarks/generate_subsets_recursive_oracle.py`](../../generate_subsets_recursive_oracle.py).

## Pinned source

- Java [`GenerateSubsets.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/recursion/GenerateSubsets.java) recursively appends the next character to the current prefix, then concatenates the include result before the exclude result.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/g/generate_subsets_recursive.c`](../../../c/g/generate_subsets_recursive.c) |
| C3 | [`c3/g/generate_subsets_recursive.c3`](../../../c3/g/generate_subsets_recursive.c3) |
| C++ | [`cpp/g/generate_subsets_recursive.cpp`](../../../cpp/g/generate_subsets_recursive.cpp) |
| Elisa | [`elisa/g/generate_subsets_recursive.elisa`](../../../elisa/g/generate_subsets_recursive.elisa) |
| Nim | [`nim/g/generate_subsets_recursive.nim`](../../../nim/g/generate_subsets_recursive.nim) |
| Odin | [`odin/g/generate_subsets_recursive.odin`](../../../odin/g/generate_subsets_recursive.odin) |
| Rust | [`rust/g/generate_subsets_recursive.rs`](../../../rust/g/generate_subsets_recursive.rs) |
| V | [`v/g/generate_subsets_recursive.v`](../../../v/g/generate_subsets_recursive.v) |
| Zig | [`zig/g/generate_subsets_recursive.zig`](../../../zig/g/generate_subsets_recursive.zig) |

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm generate_subsets_recursive --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm generate_subsets_recursive
```
