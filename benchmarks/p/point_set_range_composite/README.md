# Point Set Range Composite

This package is the canonical bounded profile for point replacement of affine maps and ordered half-open range composition. The larger Library Checker task is the same algorithm family and does not receive a duplicate large-array package here.

The task taxonomy and composition direction follow [Library Checker: Point Set Range Composite](https://judge.yosupo.jp/problem/point_set_range_composite) and its [proposal issue](https://github.com/yosupo06/library-checker-problems/issues/122). Those sources are used for operation semantics only. The bounds, scalar checksum, implementations, fixtures, and direct-scan oracle are independently authored; no task statement text or submitted source code was copied.

## Contract

The packed signed-64-bit input is:

```text
[N, Q, (a, b) * N, operation * Q]
```

Each pair represents `f_i(x) = a*x + b (mod 998244353)`. The profile limits `N` to 1..16 and `Q` to 0..32; coefficients and query arguments are residues 0..998244352.

- `0, p, c, d` replaces `f_p` with `x -> c*x + d`.
- `1, l, r, x` applies `f_l`, then `f_(l+1)`, through `f_(r-1)` to `x`. Its interval is half-open and may be empty.
- The scalar result is `sum(q * answer_q) mod 998244353`, where `q` is the one-based query number.
- A null pointer, malformed trace, out-of-domain residue, or input longer than 162 values returns `-1`.
- A trace with no queries returns `0`.

For adjacent ranges `L` then `R`, the segment tree stores `R ∘ L`: if the transforms are `(aL,bL)` and `(aR,bR)`, their combined transform is `(aR*aL, aR*bL+bR) mod 998244353`. The range query maintains separate left and right accumulators so the noncommutative composition order is preserved.

Construction takes `O(N)` time. Each point replacement and range query takes `O(log N)` time; storage is `O(N)`. The bounded profile uses a fixed power-of-two tree with 64 affine-map slots. Products of residues fit signed 64-bit arithmetic before reduction.

## Workload and oracle

[`workload.json`](workload.json) covers single maps, composition direction, point replacement, weighted query order, empty ranges, modular reduction, a non-power-of-two range, interleaved updates and queries, maximum dimensions, malformed inputs, and null input. The [direct-scan oracle](../../point_set_range_composite_oracle.py) applies every selected map in sequence. The [static workload and source checker](../../verify_point_set_range_composite.py) checks each fixture and all nine source paths without invoking a compiler.

## Implementations

All ports use the `i64_array_scalar` ABI:

| Language | Source |
| --- | --- |
| C | [`c/p/point_set_range_composite.c`](../../../c/p/point_set_range_composite.c) |
| C3 | [`c3/p/point_set_range_composite.c3`](../../../c3/p/point_set_range_composite.c3) |
| C++ | [`cpp/p/point_set_range_composite.cpp`](../../../cpp/p/point_set_range_composite.cpp) |
| Elisa | [`elisa/p/point_set_range_composite.elisa`](../../../elisa/p/point_set_range_composite.elisa) |
| Nim | [`nim/p/point_set_range_composite.nim`](../../../nim/p/point_set_range_composite.nim) |
| Odin | [`odin/p/point_set_range_composite.odin`](../../../odin/p/point_set_range_composite.odin) |
| Rust | [`rust/p/point_set_range_composite.rs`](../../../rust/p/point_set_range_composite.rs) |
| V | [`v/p/point_set_range_composite.v`](../../../v/p/point_set_range_composite.v) |
| Zig | [`zig/p/point_set_range_composite.zig`](../../../zig/p/point_set_range_composite.zig) |
