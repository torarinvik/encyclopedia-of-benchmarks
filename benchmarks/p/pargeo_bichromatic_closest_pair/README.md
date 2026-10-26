# ParGeo Bichromatic Closest Pair

This package measures a bounded 2D bichromatic closest-pair query. It builds a KD-tree for each color class and recursively visits node pairs in increasing bounding-box lower-bound distance, pruning a pair when its lower bound exceeds the best point distance already found. This is distinct from the repository's single-set divide-and-conquer closest-pair benchmark: every candidate here must contain one point from each of two separately built trees.

## Contract

- Input is `[nA, nB, ax0, ay0, ..., bx0, by0, ...]` in signed 64-bit cells.
- Each point set contains 2–8 points; coordinates are integers in `[-1,000,000, 1,000,000]`.
- Both trees use a fixed leaf capacity of 2. Internal nodes use the widest bounding-box axis, split at the coordinate-range midpoint, and fall back to a balanced split if the midpoint partition is empty. The search uses squared point distances and squared AABB lower bounds; this preserves the source's Euclidean ordering while avoiding square roots.
- Return `8` and write the minimum squared cross-set distance as one signed 64-bit little-endian value. Invalid framing or values return `-1`. Null output or capacity below 8 returns `-2` and writes nothing.
- Maximum input length is 34 cells. The bounded implementation's fixed local tree state fits within 4 KiB.

The oracle computes the cross product of the two point sets directly and does not reproduce the KD-tree or pruning algorithm. Static cases include hand-derived distances, negative coordinates, duplicate cross-set points, invalid framing, and output errors.

## Provenance and rights

The algorithm is based on ParGeo's `bichromaticClosestPair` and `bcpHelper`, with serial KD-tree construction semantics from `constructSerial` and the source node-distance lower bound. The ports are independently written and do not copy upstream implementation text.

- Repository: [ParAlg/ParGeo](https://github.com/ParAlg/ParGeo)
- Pinned revision: `4911408762c46b7c262f6d617d7adcb0cb0f219b`
- BCP source: [`include/kdTree/bccpImpl.h`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/include/kdTree/bccpImpl.h)
- KD-tree source: [`include/kdTree/treeImpl.h`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/include/kdTree/treeImpl.h)
- License: MIT; the complete repository license is in [`LICENSE.txt`](LICENSE.txt). The source header attributes the implementation to Yiqiu Wang, Shangdi Yu, Laxman Dhulipala, Yan Gu, and Julian Shun.

The integer coordinate restriction is a deterministic bounded profile of the source's double-precision geometry. The benchmark reports distance only, so equal-distance point identity and traversal ties are intentionally unobservable.
