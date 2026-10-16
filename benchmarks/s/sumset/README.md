# Sumset

The pinned Python `sumset(set_a, set_b)` returns the set of all pairwise sums `a + b`. The source set has no iteration-order contract, so this bounded integer-array ABI serializes its unique sums in ascending order as newline-delimited ASCII.

## Contract

- The `i64_array_bytes_output` ABI accepts `[count_a, count_b, *set_a, *set_b]`. Each count is 0 through 64, the array length must match both counts, and each element must be in -1,000 through 1,000. Invalid inputs return `-1`.
- Duplicate input values have set semantics. Each distinct pairwise sum is emitted once, in ascending order. If either set is empty, the output is empty.
- Insufficient output capacity returns `-2` without writing. The bounded sum domain is -2,000 through 2,000; a 24,006-byte buffer covers the worst-case output.

[`workload.json`](workload.json) covers empty sets, duplicate values, negative and boundary sums, maximum input sizes, malformed arrays, and a short output buffer.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sumset --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/sumset/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm sumset --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/s/sumset.c`](../../../c/s/sumset.c) |
| C3 | [`c3/s/sumset.c3`](../../../c3/s/sumset.c3) |
| C++ | [`cpp/s/sumset.cpp`](../../../cpp/s/sumset.cpp) |
| Elisa | [`elisa/s/sumset.elisa`](../../../elisa/s/sumset.elisa) |
| Nim | [`nim/s/sumset.nim`](../../../nim/s/sumset.nim) |
| Odin | [`odin/s/sumset.odin`](../../../odin/s/sumset.odin) |
| Rust | [`rust/s/sumset.rs`](../../../rust/s/sumset.rs) |
| V | [`v/s/sumset.v`](../../../v/s/sumset.v) |
| Zig | [`zig/s/sumset.zig`](../../../zig/s/sumset.zig) |

## TheAlgorithms reference

- [Python `sumset.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sumset.py)
