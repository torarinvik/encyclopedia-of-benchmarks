# Package inventory

Algorithm: `same_fringe_leaf_iterator`  
ABI: `i64_array_scalar`  
Input: `[nA,nB,(value,left,right)*nA,(value,left,right)*nB]`  
Bounds: 15 nodes per full binary tree, 30 total; max valid/parseable lengths 92/93  
Results: 1 equal fringe, 0 unequal fringe, -1 invalid frame/tree  
Workspace cap: 1,024 bytes

## Native ports

- `c/s/same_fringe_leaf_iterator.c`
- `cpp/s/same_fringe_leaf_iterator.cpp`
- `rust/s/same_fringe_leaf_iterator.rs`
- `elisa/s/same_fringe_leaf_iterator.elisa`
- `c3/s/same_fringe_leaf_iterator.c3`
- `nim/s/same_fringe_leaf_iterator.nim`
- `odin/s/same_fringe_leaf_iterator.odin`
- `v/s/same_fringe_leaf_iterator.v`
- `zig/s/same_fringe_leaf_iterator.zig`
- `mojo/s/same_fringe_leaf_iterator.mojo`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `__init__.py`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`

The 35–33 title-band crosswalk maps Strassen, Stirling-2, Juggler, Thiele, Kosaraju, Hierholzer, Vogel, and rooted-tree listing to existing local packages. The binomial-transform title is a related but generalized transform relative to `coloured_triangle_reduction`, not claimed as an exact duplicate. Same-fringe leaf comparison was absent from local names and contracts. `flatten_nested_list` emits a hash of flattened nested-list leaves; this package compares two tree leaf streams in lockstep and terminates leaf comparison at the first mismatch.

Sources: [Biernacki, Danvy, and Shan (2006)](https://doi.org/10.1016/j.scico.2006.01.002), §4; [Finin and Rutter (1976) scan](https://ebiquity.umbc.edu/_file_directory_/papers/1148.pdf); pinned [RosettaCodeData title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) for discovery only.
