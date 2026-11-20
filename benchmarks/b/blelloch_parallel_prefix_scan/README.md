# Blelloch parallel prefix scan

This package computes an exclusive prefix sum using the work-efficient
upsweep/downsweep scan described by Guy E. Blelloch in *Prefix Sums and Their
Applications*, CMU-CS-90-190 (1990), Section 1.2.

The ABI is `i64_array_bytes_output`. Input is `[N,a0,...,a(N-1)]`, with
`1<=N<=64`, exact length `N+1`, and values in `[-1,000,000,1,000,000]`. Let
`P` be the least power of two at least `N`; initialize a `P`-entry array with
the input followed by zero padding. At each upsweep level, combine disjoint
tree nodes from the previous level. Set the root entry to zero. At each
downsweep level, pass each node's prior value to its left child and add the
left child's saved partial sum to form the right child's prefix. The output
contains the first `N` entries: `out[0]=0` and `out[i]=sum(a[0..i))`.

Each loop level simulates a parallel barrier: updates in that level touch
disjoint endpoints. For padded size `P`, the tree performs `2(P-1)` additions
over `2 log2(P)` levels. The bounded values keep every tree partial sum within
`[-64,000,000,64,000,000]`. Output is `N` little-endian i64 values, at most
512 bytes; the declared workspace cap is 2,048 bytes. Malformed or null input
returns `-1`; null or undersized output returns `-2` without writes.

This is distinct from [`prefix_sum`](../prefix_sum/README.md), which emits
inclusive prefixes from a serial running sum and also provides range queries
and subarray-sum membership. The primary reference simulates the Blelloch tree
one level at a time; the independent reference uses a left-to-right running
sum.

Blelloch's [CMU report record](https://www.cs.cmu.edu/afs/cs.cmu.edu/project/scandal/public/papers/CMU-CS-90-190.html)
and [report text](https://www.cs.cmu.edu/~guyb/papers/Ble93.pdf) are used for
the algorithm definition and method only. Source code, examples, prose, and
fixtures are independently written. See [RIGHTS.md](RIGHTS.md).

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run while drafting this package.
