# Rights and provenance

The bounded benchmark was derived from the algorithm description in the [NIST Dictionary of Algorithms and Data Structures entry](https://xlinux.nist.gov/dads/HTML/linearProbingSort.html). NIST describes interpolation-based slot selection, linear probing on collisions, and a compaction pass. The ten language ports and references are clean-room implementations; no implementation source or prose was copied.

The local profile adds a byte-key range and a deterministic table-size rule so its bounded `sort_call` contract guarantees that probe runs for distinct keys do not overlap.
