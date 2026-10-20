# Euclidean t-spanner

This profile constructs a bounded 2D Euclidean t-spanner from ParGeo's
well-separated-pair representative graph. It builds a deterministic median
split tree, decomposes the point set into well-separated node pairs, then
connects one representative from each accepted pair. The source sets the
separation factor to `s = 4*(t+1)/(t-1)`; the resulting graph has stretch at
most `t` for every input point pair.

## Contract

The ABI is `float64_slice_io`, symbol `euclidean_t_spanner`. Input is
`[n,t,x0,y0,...]`; `n` is 2..8, `t` is in [1.5,4], and coordinates are
finite, integer-valued binary64 numbers in [-1000,1000]. Coordinates must be
distinct. Output is `[edge_count,u0,v0,...]`, with each undirected endpoint
pair normalized so `u < v`; indices are exact-valued doubles. Edges follow
the deterministic depth-first WSPD traversal order. Invalid input returns
`-1` before output checks. Null output or capacity below the exact result
length returns `-2` without writing. At most 28 edges and 57 output elements
are possible.

The source tree partitions by its widest bounding-box axis and recursively
splits the larger-span node when a pair is not separated. This bounded profile
uses median partitions with deterministic coordinate/index ties and the
source's bounding-box sphere rule
`distance(centerA,centerB) - radiusA - radiusB >= s*max(radiusA,radiusB)`.
Representatives are the smallest original input indices in their nodes.
These deterministic choices may differ from ParGeo's in-place partition
order while preserving the separation rule and t-stretch guarantee.

The existing [`wspd`](../wspd/README.md) benchmark returns decomposition
pairs as point masks. This package instead turns each pair into a graph edge
between its representatives and measures the spanner construction.

## Pinned source and license

Based on ParGeo's [`spanner.cpp`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/src/spatialGraph/spanner/spanner.cpp)
and [`wspdImpl.h`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/include/kdTree/wspdImpl.h),
commit `4911408762c46b7c262f6d617d7adcb0cb0f219b`. The repository is MIT
licensed; the complete notice is bundled in [`LICENSE.txt`](LICENSE.txt).

[`workload.json`](workload.json) contains fixtures and limits. The independent
oracle is [`euclidean_t_spanner_oracle.py`](../../euclidean_t_spanner_oracle.py).
