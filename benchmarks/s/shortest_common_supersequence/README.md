# Shortest Common Supersequence

Construct a shortest sequence that contains both input sequences as subsequences. The benchmark follows the pinned C++ dynamic-programming implementation and the corresponding R routine. Both derive the output from an LCS table and choose the right-hand sequence (Y) when the two predecessor LCS lengths tie.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[left_length, right_length, left_ascii_values..., right_ascii_values...]` with exact length `2 + left_length + right_length`.
- Each sequence length is in `0..=64`; each value is a printable ASCII byte in `32..=126`. The maximum packed input length is 130.
- The output is the raw ASCII bytes of the shortest common supersequence, with no terminator or length prefix. The return value is the byte count; at most 128 bytes are needed.
- Malformed framing, out-of-range lengths, or non-printable values return `-1`. Input validation precedes output-buffer checks.
- A null output pointer or capacity smaller than the computed output length returns `-2` without writing. Empty inputs produce a zero-byte result; a non-null output pointer with capacity zero succeeds.
- The tie rule is observable. During reverse backtracking, when `LCS[i-1][j] == LCS[i][j-1]`, the algorithm consumes a character from Y, then reverses the collected output.

The printable ASCII domain makes each source byte correspond to one R character and avoids differences in Unicode indexing. The R example wrapper lowercases interactive input; the benchmark calls the pure routine directly and preserves the supplied case.

## Workload

[`workload.json`](workload.json) covers empty and identical inputs, repeated characters, a classic LCS example, a tie that distinguishes Y from X, printable ASCII boundaries, maximum output size, malformed inputs, null pointers, and output-capacity boundaries. See the [oracle](../../shortest_common_supersequence_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/shortest_common_supersequence.c`](../../../c/s/shortest_common_supersequence.c) |
| C3 | [`c3/s/shortest_common_supersequence.c3`](../../../c3/s/shortest_common_supersequence.c3) |
| C++ | [`cpp/s/shortest_common_supersequence.cpp`](../../../cpp/s/shortest_common_supersequence.cpp) |
| Elisa | [`elisa/s/shortest_common_supersequence.elisa`](../../../elisa/s/shortest_common_supersequence.elisa) |
| Nim | [`nim/s/shortest_common_supersequence.nim`](../../../nim/s/shortest_common_supersequence.nim) |
| Odin | [`odin/s/shortest_common_supersequence.odin`](../../../odin/s/shortest_common_supersequence.odin) |
| Rust | [`rust/s/shortest_common_supersequence.rs`](../../../rust/s/shortest_common_supersequence.rs) |
| V | [`v/s/shortest_common_supersequence.v`](../../../v/s/shortest_common_supersequence.v) |
| Zig | [`zig/s/shortest_common_supersequence.zig`](../../../zig/s/shortest_common_supersequence.zig) |

## Pinned sources

- [TheAlgorithms/C-Plus-Plus — `shortest_common_supersequence.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/shortest_common_supersequence.cpp) at `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- [TheAlgorithms/R — `shortest.common.supersequence.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/shortest.common.supersequence.r) at `f65344fabeea0ae33c1ca321af709447c1a8a4c2`.

The C++ and R routines use the same LCS recurrence and backtracking choice. The package also retains that reverse-building order so inputs with multiple shortest solutions have a stable, source-compatible output.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm shortest_common_supersequence --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/shortest_common_supersequence/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm shortest_common_supersequence
```
