# Suffix balanced tree

This benchmark builds a suffix array by inserting suffixes from right to left into a scapegoat-style balanced search tree. Each suffix is a node. The comparison examines the first symbol and, when those symbols match, compares the order tags of the successor suffixes. In-order traversal yields all suffix starts in lexicographic order.

## Bounded ABI

The exported symbol is `suffix_balanced_tree` with the `i64_array_bytes_output` ABI:

```c
int64_t suffix_balanced_tree(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity);
```

Input is `[N, symbol_0, ..., symbol_(N-1)]`, with `0 <= N <= 32` and byte symbols in `0..255`. Output is the zero-based suffix starts as little-endian signed 64-bit integers. Malformed input returns `-1`. A null output pointer or capacity below `8*N` returns `-2`, including for empty text; a nonnull zero-capacity buffer succeeds for `N=0` and returns `0`. Maximum input is 33 words and maximum output is 256 bytes.

## Algorithm

The tree stores subtree sizes and an integer order tag for each suffix. For equal first symbols, suffix `i` precedes suffix `j` exactly when the tag of suffix `i+1` is smaller than the tag of suffix `j+1`. The empty suffix uses tag zero. The implementation inserts positions `N-1` through `0` and rebuilds a subtree when four times its larger child exceeds three times its size. Rebuilding preserves the subtree's in-order suffix order and assigns midpoint tags within the inherited interval. Tags fit in the fixed interval `[0, 2^62)` for the local bound.

Each comparison takes `O(1)`. Scapegoat-style insertions and rebuilds take `O(N log N)` amortized total time; in-order output takes `O(N)`, and storage is `O(N)`. The primary oracle reproduces the tagged scapegoat construction. The independent oracle sorts complete suffix slices directly. The workload includes repeated and periodic symbols, an embedded zero byte, empty input, and output-buffer errors; see [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py), and [`independent_oracle.py`](independent_oracle.py).

This construction is distinct from [`suffix_array`](../suffix_array/README.md), which uses rank doubling, and [`suffix_array_dc3`](../suffix_array_dc3/README.md), which uses a difference-cover sample and recursive merge.

## Source and rights

Algorithm reference: [OI Wiki Suffix Balanced Tree](https://oi-wiki.org/string/suffix-bst/). The article lists CC BY-SA 4.0 and SATA terms; see [RIGHTS.md](RIGHTS.md). Only its algorithm description informs these clean-room ports, workload, oracles, and documentation.

## Ports

| Language | Source |
|---|---|
| C | [`c/s/suffix_balanced_tree.c`](../../../c/s/suffix_balanced_tree.c) |
| C3 | [`c3/s/suffix_balanced_tree.c3`](../../../c3/s/suffix_balanced_tree.c3) |
| C++ | [`cpp/s/suffix_balanced_tree.cpp`](../../../cpp/s/suffix_balanced_tree.cpp) |
| Elisa | [`elisa/s/suffix_balanced_tree.elisa`](../../../elisa/s/suffix_balanced_tree.elisa) |
| Mojo | [`mojo/s/suffix_balanced_tree.mojo`](../../../mojo/s/suffix_balanced_tree.mojo) |
| Nim | [`nim/s/suffix_balanced_tree.nim`](../../../nim/s/suffix_balanced_tree.nim) |
| Odin | [`odin/s/suffix_balanced_tree.odin`](../../../odin/s/suffix_balanced_tree.odin) |
| Rust | [`rust/s/suffix_balanced_tree.rs`](../../../rust/s/suffix_balanced_tree.rs) |
| V | [`v/s/suffix_balanced_tree.v`](../../../v/s/suffix_balanced_tree.v) |
| Zig | [`zig/s/suffix_balanced_tree.zig`](../../../zig/s/suffix_balanced_tree.zig) |

The package-local static inventory and oracle checker is [`verify_workload.py`](verify_workload.py); it has not been run. The shared byte-output suite registers the bounds, independent suffix-sort oracle, maximum text, empty text, and malformed/capacity profiles; the suite has not been run.
