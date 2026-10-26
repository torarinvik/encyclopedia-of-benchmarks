# TSVC s111 odd-index neighbor update

This package implements the pinned TSVC `s111` loop: for odd indices `i`, assign `A[i] = A[i-1] + B[i]`; even A entries are preserved. The source iterates in ascending index order by two. Since every source index is even, writes do not affect subsequent reads, but the ports retain the source traversal.

Input is `[n, A[0..n), B[0..n)]`, where `1 <= n <= 64` and all vector values are finite integer-valued binary64 numbers in `[-1000,1000]`. Output is the complete updated A vector. The input domain guarantees exact integer-valued results in binary32 and binary64. Invalid input returns `-1`; a null output or capacity below n returns `-2` after validation. ABI: `float64_slice_io`.

Provenance: `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc::s111` (lines 845–869), selected by the `LinearDependence-dbl` and `LinearDependence-flt` launchers. The pinned launchers use `3570 14` and `3570 5`, respectively; the package exposes one bounded pass. This operation is distinct from s131's all-index forward-neighbor update because s111 writes only odd destinations. TSVC attributes its non-four-digit loops to David Callahan, Jack Dongarra, and David Levine. No explicit redistribution grant was found. These nine ports are clean-room implementations and reuse no upstream code or comments.

See [workload.json](workload.json), [LICENSE.txt](LICENSE.txt), and the [independent oracle](../../tsvc_s111_odd_index_neighbor_update_oracle.py).
