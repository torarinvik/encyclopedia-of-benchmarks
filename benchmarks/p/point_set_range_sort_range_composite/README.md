# Point Set Range Sort Range Composite

This package adapts the [Library Checker task](https://judge.yosupo.jp/problem/point_set_range_sort_range_composite) to a bounded scalar call. The sequence stores records `(p, a, b)`, where `(a,b)` defines `f(x)=a*x+b mod 998244353`. Operations replace a point record, sort a half-open range by its distinct priority in ascending or descending order, or evaluate the ordered affine composition over a range.

## Contract

The scalar ABI is `int64_t point_set_range_sort_range_composite(const int64_t *input, size_t length)`. The packed input begins `[N,Q,(p_i,a_i,b_i)*N]`, followed by `Q` variable-length operations:

- `0 i p a b` replaces record `i` with `(p,a,b)`.
- `1 l r x` applies records at positions `l` through `r-1` in order to `x`.
- `2 l r` sorts `[l,r)` by priority ascending.
- `3 l r` sorts `[l,r)` by priority descending.

The local bounds are `1 <= N <= 16` and `1 <= Q <= 32`. Priorities are in `[0,10^9]` and are globally distinct across initial records and every point-replacement priority, as in the official task. Affine coefficients satisfy `1 <= a < 998244353`; offsets and query values satisfy `0 <= b,x < 998244353`. Every operation range is nonempty and half-open, `0 <= l < r <= N`. Invalid or malformed input and null pointers return `-1`.

The result is `sum(k * answer_k) mod 998244353`, where `k` is the one-based ordinal among type-1 query results. A trace with no type-1 operations returns zero. The maximum packed length is 210 signed 64-bit values. Ports parse operations in order, maintain a bounded record array, sort each requested slice, and directly apply the selected affine maps. This intentionally bounded simulation keeps sorting and ordering behavior explicit.

This is distinct from [`point_set_range_composite`](../point_set_range_composite/README.md), which supports point replacement and range composition while preserving the original index order. It is also distinct from [`range_set_range_composite`](../../r/range_set_range_composite/README.md), which assigns one affine map over an interval but does not sort records by priority.

## Workload and oracles

[`workload.json`](workload.json) includes both official samples, ascending and descending order changes, point replacement, composition order, duplicate-priority rejection, malformed traces, and null input. [`primary_oracle.py`](primary_oracle.py) simulates a list of records and built-in range sorts. [`independent_oracle.py`](independent_oracle.py) stores the record order as priority IDs, uses a separate priority-to-map table, and selection-sorts the requested ID slice.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/point_set_range_sort_range_composite.c`](../../../c/p/point_set_range_sort_range_composite.c) |
| C3 | [`c3/p/point_set_range_sort_range_composite.c3`](../../../c3/p/point_set_range_sort_range_composite.c3) |
| C++ | [`cpp/p/point_set_range_sort_range_composite.cpp`](../../../cpp/p/point_set_range_sort_range_composite.cpp) |
| Elisa | [`elisa/p/point_set_range_sort_range_composite.elisa`](../../../elisa/p/point_set_range_sort_range_composite.elisa) |
| Mojo | [`mojo/p/point_set_range_sort_range_composite.mojo`](../../../mojo/p/point_set_range_sort_range_composite.mojo) |
| Nim | [`nim/p/point_set_range_sort_range_composite.nim`](../../../nim/p/point_set_range_sort_range_composite.nim) |
| Odin | [`odin/p/point_set_range_sort_range_composite.odin`](../../../odin/p/point_set_range_sort_range_composite.odin) |
| Rust | [`rust/p/point_set_range_sort_range_composite.rs`](../../../rust/p/point_set_range_sort_range_composite.rs) |
| V | [`v/p/point_set_range_sort_range_composite.v`](../../../v/p/point_set_range_sort_range_composite.v) |
| Zig | [`zig/p/point_set_range_sort_range_composite.zig`](../../../zig/p/point_set_range_sort_range_composite.zig) |

## Source and rights

The operation semantics and priority constraint are attributed to [Library Checker: Point Set Range Sort Range Composite](https://judge.yosupo.jp/problem/point_set_range_sort_range_composite) and the task source in [yosupo06/library-checker-problems](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/point_set_range_sort_range_composite/task.md). The upstream problem repository is Apache-2.0 except for separately identified third-party material. These package ports are clean-room implementations; no submitted solution source is copied.
