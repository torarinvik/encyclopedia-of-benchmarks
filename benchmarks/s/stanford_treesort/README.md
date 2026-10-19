# Stanford Treesort benchmark

## Contract

The pinned launcher compiles `Treesort.c` with `-lm` and runs it without options. `main` calls `Trees(run)` 100 times. Each pass resets the seed to 74755, generates 5000 keys with `seed = (seed * 1309 + 13849) & 65535`, and maps each generated number to `temp - (temp / 100000) * 100000 - 50000`. It then inserts keys into an unbalanced binary search tree and checks the tree.

The upstream inserts greater keys to the left and smaller keys to the right. Its strict `>` and `<` cases omit equal keys, so duplicates are dropped. It prints `sortlist[2 + run]` using the source’s 1-based indexing, rather than traversing the tree to print a sorted list. Because every pass resets the random seed, the suite’s `runs` parameter returns the first `runs` lines of the same deterministic sequence, starting at the second generated key. The launcher default is `runs=100`.

## ABI and workload

The `i64_scalar_bytes_output` entry point is `stanford_treesort(runs, output, output_capacity)`, with `runs` in 1..100. Each requested pass performs the full key generation, tree insertion, and tree check. It returns the exact source stdout bytes, -1 for invalid input, and -2 for a null or undersized output buffer. Ports stage output before copying it; the maximum output is 700 bytes.

[workload.json](workload.json) covers one pass, two passes, the launcher default, signed-boundary invalid inputs, and buffer errors. [stanford_treesort_oracle.py](../../stanford_treesort_oracle.py) independently regenerates the keys and applies the duplicate-dropping insertion and strict reversed-order check. The separate [`tree_sort`](../tree_sort/README.md) package preserves duplicate keys and therefore does not reproduce this benchmark’s insertion behavior.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/stanford_treesort.c](../../../c/s/stanford_treesort.c) |
| C3 | [c3/s/stanford_treesort.c3](../../../c3/s/stanford_treesort.c3) |
| C++ | [cpp/s/stanford_treesort.cpp](../../../cpp/s/stanford_treesort.cpp) |
| Elisa | [elisa/s/stanford_treesort.elisa](../../../elisa/s/stanford_treesort.elisa) |
| Nim | [nim/s/stanford_treesort.nim](../../../nim/s/stanford_treesort.nim) |
| Odin | [odin/s/stanford_treesort.odin](../../../odin/s/stanford_treesort.odin) |
| Rust | [rust/s/stanford_treesort.rs](../../../rust/s/stanford_treesort.rs) |
| V | [v/s/stanford_treesort.v](../../../v/s/stanford_treesort.v) |
| Zig | [zig/s/stanford_treesort.zig](../../../zig/s/stanford_treesort.zig) |

## Pinned source

- [Treesort.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Treesort/Treesort.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Treesort/info.sh)
