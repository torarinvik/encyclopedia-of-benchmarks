# McCat 17-bintr: recursive binary-tree membership

The pinned McCat benchmark constructs a binary search tree by sorted
insertion, reports its size, sum, and arithmetic mean, then performs 100
membership probes using `memberOfBinaryTree`. That function searches
recursively in generic left-first depth-first order. The source also defines
`memberOfSortedBinaryTree`, which follows key comparisons, but the call to that
function is commented out in the benchmark launcher. This workload therefore
measures a distinct membership algorithm from local
[`binary_search_tree`](../binary_search_tree/README.md), whose lookup follows
key-directed branches.

## Contract

The `i64_array_bytes_output` interface accepts
`[node_count, node_values..., 100, probe_values...]`. Node count is 1–64. The
function inserts values in order; duplicate values do not change the tree.
Exactly 100 probes follow. Tree values and probes are nonzero signed 16-bit
integers, matching the source's zero list terminator. The bounded structured
input omits terminators and rejects zero values.

The returned 33 bytes contain a four-byte little-endian tree size, the
recursive sum and arithmetic mean as little-endian binary64, and a 13-byte hit
bitmap for the 100 probes. Probe `i` is stored in bit `i % 8` of byte `i / 8`.
The source's mean divides by tree size, so empty trees are excluded. Invalid
inputs return `-1`; a null or undersized output buffer returns `-2` without
writes. The independent Python oracle builds the sorted tree and runs its own
left-first recursive membership search.

The source uses sentinel-terminated stdin lists and the launcher dataset. This
package represents the defined full 100-probe behavior through a bounded
array contract and does not include input parsing or printing.

## Provenance and license

Pinned source: [`lac-dcc/Benchmarks` McCat/17-bintr at commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/17-bintr).
The benchmark source grants redistribution and modification provided the
copyright notice remains. Its complete notice is reproduced here and in each
port:

> Copyright (C) 1996 McGill University.  
> Copyright (C) 1996 McCAT System Group.  
> Copyright (C) 1996 ACAPS Benchmark Administrator  
> benadmin@acaps.cs.mcgill.ca
>
> This program is free software; you can redistribute it and/or modify it
> provided this copyright notice is maintained.
>
> This program is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/mccat_bintr.c](../../../c/m/mccat_bintr.c) |
| C3 | [c3/m/mccat_bintr.c3](../../../c3/m/mccat_bintr.c3) |
| C++ | [cpp/m/mccat_bintr.cpp](../../../cpp/m/mccat_bintr.cpp) |
| Elisa | [elisa/m/mccat_bintr.elisa](../../../elisa/m/mccat_bintr.elisa) |
| Nim | [nim/m/mccat_bintr.nim](../../../nim/m/mccat_bintr.nim) |
| Odin | [odin/m/mccat_bintr.odin](../../../odin/m/mccat_bintr.odin) |
| Rust | [rust/m/mccat_bintr.rs](../../../rust/m/mccat_bintr.rs) |
| V | [v/m/mccat_bintr.v](../../../v/m/mccat_bintr.v) |
| Zig | [zig/m/mccat_bintr.zig](../../../zig/m/mccat_bintr.zig) |

Independent oracle: [`mccat_bintr_oracle.py`](../../mccat_bintr_oracle.py).
