# Permute string

## Contract

This benchmark extracts the pinned Java method's unique permutation set for bounded ASCII strings. Input is a signed-i64 array [character_count, ASCII_code_units...], with 0 <= character_count <= 7, exact length character_count + 1, and each Java UTF-16 code unit in 0..127 (including U+0000). The seven-unit bound keeps the largest output to 7 * 7! = 35,280 bytes.

The source recursively swaps each char position and inserts completed strings into a HashSet, so repeated input characters produce only distinct strings. HashSet iteration order is unspecified; the benchmark serializes the same set as lexicographically sorted, fixed-width rows. Each row contains character_count raw ASCII bytes, and rows are concatenated without separators. The returned byte length divided by character_count gives the number of permutations when the count is nonzero.

An empty input string produces an empty set, not a set containing the empty string; its result is zero output bytes. The Java method's Javadoc says null returns an empty set, but its implementation dereferences str.length(). A null ABI input pointer and malformed packed input return -1 before output checks. A valid null output pointer returns -2, even for an empty result. A nonnull output buffer with capacity zero succeeds for the empty set; capacity below the required byte count returns -2 without writes.

## Workload

[workload.json](workload.json) covers empty input, single and repeated characters, duplicate elimination, embedded NUL code units, lexicographic output, maximum input/output, null input/output, short capacity, and invalid framing/domain cases.

## TheAlgorithms reference

- Java [PermuteString.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/PermuteString.java) at commit e43ec3897e48f23843972d02cd05a5bb1b6864a2, symbol PermuteString.getPermutations. The implementation uses recursive swaps and a HashSet.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/permute_string.c](../../../c/p/permute_string.c) |
| C3 | [c3/p/permute_string.c3](../../../c3/p/permute_string.c3) |
| C++ | [cpp/p/permute_string.cpp](../../../cpp/p/permute_string.cpp) |
| Elisa | [elisa/p/permute_string.elisa](../../../elisa/p/permute_string.elisa) |
| Nim | [nim/p/permute_string.nim](../../../nim/p/permute_string.nim) |
| Odin | [odin/p/permute_string.odin](../../../odin/p/permute_string.odin) |
| Rust | [rust/p/permute_string.rs](../../../rust/p/permute_string.rs) |
| V | [v/p/permute_string.v](../../../v/p/permute_string.v) |
| Zig | [zig/p/permute_string.zig](../../../zig/p/permute_string.zig) |

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm permute_string --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm permute_string
```
