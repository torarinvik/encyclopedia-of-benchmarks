# Tree addition

This package ports the Olden `treeadd` program from the pinned
[`Olden/treeadd` source directory](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/treeadd)
in `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
Its launcher compiles `args.c`, `node.c`, and `par-alloc.c` with `-lm -DTORONTO`.
It runs level 22 by default or level 20 when `SMALL_PROBLEM_SIZE` is set; the
source uses four processors when no processor count is passed.

`TreeAlloc` builds a full binary tree with value one at every node. `TreeAdd`
recursively sums the node and both subtrees, and `main` invokes it 100 times,
returning the last result. The wrapper takes the tree level as one signed
integer and caps it at 12, which limits the tree to 4095 nodes while retaining
the source's tree construction and recursive traversal. Level zero represents
the source's null tree and returns zero; levels outside 0 through 12 return -1.
The ports store nodes in a bounded contiguous table with left and right child
indices, preserving the generated topology and recursive walk. The pinned
reference runs report 1,048,575 at level 20 and 4,194,303 at level 22; those
launcher levels are outside the portable wrapper's bound.

The independent oracle derives the full-tree sum by accumulating each level's
node count in [`benchmarks/treeadd_oracle.py`](../../treeadd_oracle.py).

The pinned `node.c` and `par-alloc.c` each refer to `olden_v1.0/COPYRIGHT`, but
that path is absent from this snapshot. These ports are independently written;
no license is inferred from the missing file.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/t/treeadd.c](../../../c/t/treeadd.c) |
| C3 | [c3/t/treeadd.c3](../../../c3/t/treeadd.c3) |
| C++ | [cpp/t/treeadd.cpp](../../../cpp/t/treeadd.cpp) |
| Elisa | [elisa/t/treeadd.elisa](../../../elisa/t/treeadd.elisa) |
| Nim | [nim/t/treeadd.nim](../../../nim/t/treeadd.nim) |
| Odin | [odin/t/treeadd.odin](../../../odin/t/treeadd.odin) |
| Rust | [rust/t/treeadd.rs](../../../rust/t/treeadd.rs) |
| V | [v/t/treeadd.v](../../../v/t/treeadd.v) |
| Zig | [zig/t/treeadd.zig](../../../zig/t/treeadd.zig) |

Run the shared scalar suite with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm treeadd --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/t/treeadd/c/build.json
python3 benchmarks/verify_scalar.py --algorithms treeadd --languages c
```
