# Rights and provenance

The benchmark contract and official constraints are described by Library
Checker's `Min Plus Convolution (Convex and Convex)` task in the
[yosupo06/library-checker-problems](https://github.com/yosupo06/library-checker-problems)
repository, which is licensed under Apache-2.0. The local source ports and
oracles are clean-room implementations. No judge solution or AtCoder code was
copied.

The linear-time algorithmic idea is attributed to the
[AtCoder Algorithm Lecture on min-plus convolution](https://info.atcoder.jp/entry/algorithm_lectures/min_plus_convolution):
merge the sorted first-difference sequences, then prefix-sum their union.
