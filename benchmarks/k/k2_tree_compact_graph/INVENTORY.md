# Package inventory

This package contains a bounded directed-graph k²-tree profile with packed
`T` and `L` bitmaps, rank-prefix navigation, direct row-mask independent
reference, workload fixtures, provenance, and ten language ports.

The fixed native tables use 43 bytes for `T`, 128 bytes for `L`, 682 bytes for
the u16 rank-prefix table, and 1,024 bytes for current/next region coordinates
(four 256-byte arrays), totaling 1,877 bytes within the 4,096-byte workspace
cap. Input and caller output buffers are excluded. The maximum valid and
parseable input lengths are 418 and 419 i64 words; maximum output is 1,032
bytes. The fixtures include a successful maximum-size 418-word frame with 128
queries and the full 1,032-byte result vector.

The inventory checker checks paths, ABI metadata, source symbols, and package
provenance without compiling or running a port. The workload helper reconciles
fixtures against the packed-tree primary and direct row-mask independent
reference. Neither helper has been executed.
