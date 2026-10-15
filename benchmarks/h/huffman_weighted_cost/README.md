# Huffman Weighted Cost

This benchmark preserves the weighted bit cost of Huffman coding while ignoring codeword identities, which can vary when frequencies tie. The cost is `sum(frequency * code_length)` for the generated binary prefix tree.

## Contract

Input is a signed 64-bit array `[symbol_count, symbol_id, frequency, ...]`. `symbol_count` is 2 through 26; each `symbol_id` is the ASCII value of a distinct lowercase letter (`a` through `z`), and each frequency is positive. The sum of frequencies must fit a signed 32-bit integer, matching the pinned C++ and Java source bounds.

The output is the weighted cost as one little-endian signed 64-bit integer. The function also returns that cost. Malformed input returns `-1`; insufficient output capacity returns `-2`. A single-symbol tree is excluded because the source implementations do not share a code-length convention for that case.

The implementation repeatedly merges the two smallest active weights and adds each merged weight to the result. This equals the sum of each symbol's frequency multiplied by its code length, regardless of tie ordering.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm huffman_weighted_cost --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/huffman_weighted_cost/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/huffman_weighted_cost.c`](../../../c/h/huffman_weighted_cost.c) |
| C3 | [`c3/h/huffman_weighted_cost.c3`](../../../c3/h/huffman_weighted_cost.c3) |
| C++ | [`cpp/h/huffman_weighted_cost.cpp`](../../../cpp/h/huffman_weighted_cost.cpp) |
| Elisa | [`elisa/h/huffman_weighted_cost.elisa`](../../../elisa/h/huffman_weighted_cost.elisa) |
| Nim | [`nim/h/huffman_weighted_cost.nim`](../../../nim/h/huffman_weighted_cost.nim) |
| Odin | [`odin/h/huffman_weighted_cost.odin`](../../../odin/h/huffman_weighted_cost.odin) |
| Rust | [`rust/h/huffman_weighted_cost.rs`](../../../rust/h/huffman_weighted_cost.rs) |
| V | [`v/h/huffman_weighted_cost.v`](../../../v/h/huffman_weighted_cost.v) |
| Zig | [`zig/h/huffman_weighted_cost.zig`](../../../zig/h/huffman_weighted_cost.zig) |

## Pinned sources

- C++ [`huffman.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/huffman.cpp)
- Java [`Huffman.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/Huffman.java)
- Python [`huffman.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/huffman.py)
