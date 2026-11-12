# Persistent Queue

This bounded profile follows Library Checker’s branching persistent queue contract. Each operation creates a new version from any earlier version: opcode `0` appends an integer, and opcode `1` removes and returns the front element. Version `-1` denotes the empty queue. A pop from an empty version is invalid.

The ports store each version as a persistent segment-tree root and two queue offsets. Appending path-copies the tree path at the version’s tail position. Popping reads the value at the head position and advances only that version’s head. This gives branching histories with shared structure; the existing `clojure_persistent_list_queue` benchmark exercises one FIFO trace without historical branching.

The local profile bounds `Q` at 128 and values at 0 through 1,000,000,000. The official task allows `Q` through 500,000 with the same value range. The input uses `[Q, operations...]`, where an append is `(0, parent_version, value)` and a pop is `(1, parent_version)`. Parents satisfy `-1 <= parent_version < operation_index`, and each pop parent must be nonempty. Successful output is one signed 64-bit little-endian popped value per pop, in operation order.

For `Q` operations, each append copies `O(log Q)` segment-tree nodes and each pop reads in `O(log Q)` time. The profile reserves a power-of-two tree domain of 128 positions and version arrays, with `O(Q log Q)` fixed node storage. The output buffer is 1,016 bytes: since the initial version is empty, at most `Q-1` of the 128 operations can pop.

`persistent_queue_oracle.py` is an independent direct model that copies Python lists per version. `verify.py` checks the package metadata and fixtures against both that model and its own direct sequence simulation. The workload data and all language ports are original clean-room implementations based on the public operation contract.

## Provenance

- [Library Checker: Persistent Queue task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/persistent_queue/task.md)
- [Library Checker: official limits](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/persistent_queue/info.toml)
