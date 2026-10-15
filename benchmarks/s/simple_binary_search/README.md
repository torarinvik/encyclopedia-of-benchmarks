# Simple binary search

Check whether a target appears in an ascending sequence using recursive binary search. Return a boolean encoded as an integer: `1` when found and `0` when absent. This membership result differs from [`binary_search`](../../b/binary_search/README.md), which returns an index.

## Contract

- Input is an ascending, nondecreasing array of signed 64-bit integers and a signed 64-bit target.
- Empty arrays are valid. The workload uses ascending arrays up to 1,048,576 values.
- Return `1` when at least one value equals the target and `0` otherwise. Return `-1` when the length exceeds the bound.

The pinned Python function recursively searches left and right slices and returns a boolean. These ports recurse over half-open index ranges to preserve the binary-search steps without language-specific array copying. They use O(log n) call-stack space.

## Source and workload

The pinned Python [`simple_binary_search.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/simple_binary_search.py) uses recursive slicing and returns `True` or `False`. [`workload.json`](workload.json) covers empty input, first/middle/last hits, and misses at lengths 0, 16, 256, and 4,096. All nine implementations use the shared search ABI and portable C11 runner. Build one with `python3 benchmarks/build_abi.py --family search --algorithm simple_binary_search --language c`; record it with `benchmarks/run.py` using the resulting executable and build provenance.

| Language | Source |
| --- | --- |
| C | [`c/s/simple_binary_search.c`](../../../c/s/simple_binary_search.c) |
| C3 | [`c3/s/simple_binary_search.c3`](../../../c3/s/simple_binary_search.c3) |
| C++ | [`cpp/s/simple_binary_search.cpp`](../../../cpp/s/simple_binary_search.cpp) |
| Elisa | [`elisa/s/simple_binary_search.elisa`](../../../elisa/s/simple_binary_search.elisa) |
| Nim | [`nim/s/simple_binary_search.nim`](../../../nim/s/simple_binary_search.nim) |
| Odin | [`odin/s/simple_binary_search.odin`](../../../odin/s/simple_binary_search.odin) |
| Rust | [`rust/s/simple_binary_search.rs`](../../../rust/s/simple_binary_search.rs) |
| V | [`v/s/simple_binary_search.v`](../../../v/s/simple_binary_search.v) |
| Zig | [`zig/s/simple_binary_search.zig`](../../../zig/s/simple_binary_search.zig) |
