# Combination Sum

This benchmark compares the recursive backtracking algorithm from TheAlgorithms/Python and TheAlgorithms/Java. Each recursive branch chooses a candidate and may reuse it, while advancing the next choice only after that branch returns. The result is the ordered list of unique nondecreasing combinations whose values sum to the target.

## Contract

- Input is `[candidate_count, target, candidates...]`.
- Candidate count is 1 through 8. Candidates are distinct, strictly ascending integers from 1 through 24. Target is 0 through 20.
- The returned bytes are little-endian signed 64-bit values: `[combination_count, length_0, values..., length_1, values..., ...]`. Combination order follows depth-first candidate order. Target zero produces one empty combination, encoded as `[1, 0]`; no solution produces `[0]`.
- Invalid input returns `-1`; insufficient output capacity returns `-2`. Implementations use portable scalar integer operations.
- The output workspace is 32,768 bytes (4,096 signed 64-bit words), enough for the largest packed result in the bounded domain.

The 4,096-word scratch limit covers the largest encoded result in this input domain. With at most eight distinct positive candidates and target at most 20, the maximum occurs for candidates 1 through 8 and target 20 (4,063 words).

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm combination_sum --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/combination_sum/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm combination_sum
```

[`combination_sum_oracle.py`](../../combination_sum_oracle.py) computes the ordered combinations and their packed representation independently.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/combination_sum.c`](../../../c/c/combination_sum.c) |
| C3 | [`c3/c/combination_sum.c3`](../../../c3/c/combination_sum.c3) |
| C++ | [`cpp/c/combination_sum.cpp`](../../../cpp/c/combination_sum.cpp) |
| Elisa | [`elisa/c/combination_sum.elisa`](../../../elisa/c/combination_sum.elisa) |
| Nim | [`nim/c/combination_sum.nim`](../../../nim/c/combination_sum.nim) |
| Odin | [`odin/c/combination_sum.odin`](../../../odin/c/combination_sum.odin) |
| Rust | [`rust/c/combination_sum.rs`](../../../rust/c/combination_sum.rs) |
| V | [`v/c/combination_sum.v`](../../../v/c/combination_sum.v) |
| Zig | [`zig/c/combination_sum.zig`](../../../zig/c/combination_sum.zig) |

## Pinned sources

- Python [`combination_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/combination_sum.py)
- Java [`CombinationSum.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/CombinationSum.java)
