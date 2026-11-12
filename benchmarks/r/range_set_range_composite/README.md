# Range set range composite

This package maintains a sequence of affine maps over `998244353`, supports
assigning one affine map to a half-open interval, and evaluates the ordered
composition over a half-open interval.

## Contract

The byte-output input starts with `[N,Q]`, then `N` coefficient pairs
`(a,b)`, then `Q` variable-width operations. Update `0 l r c d` assigns
`f_i(x)=c*x+d` for every `i` in `[l,r)`. Query `1 l r x` evaluates
`f_(r-1)(...f_(l+1)(f_l(x))) mod 998244353`. Local bounds are `1<=N<=64`,
`1<=Q<=32`, `1<=a,c<MOD`, `0<=b,d,x<MOD`, and `0<=l<r<=N`. Outputs are
little-endian signed 64-bit query values in operation order. Invalid input
returns `-1`; null output or insufficient capacity returns `-2`, without
writes. Maximum valid framing is 290 words (291 parseable), output is at most
256 bytes, and declared workspace is 16,384 bytes.

## Lazy segment tree

Each node stores the affine map for its interval in left-to-right application
order. Combining left aggregate `L` and right aggregate `R` stores `R o L`.
A range assignment tag stores the affine map `(c,d)`. Applying it to a node of
length `k` computes the repeated composition `(c*x+d)^k` by binary
exponentiation; pushing the tag applies that rule using each child's length.
Range queries combine covered nodes in their original sequence order.

This differs from `point_set_range_composite`, which changes only one map per
update. The official task permits `N,Q<=500,000`; the local profile is bounded
and does not claim support for those maximum limits. The primary oracle
simulates assignments on a direct coefficient array; the independent checker
forms each query's affine composition by scanning that array.

## Upstream and rights

See [Library Checker: Range Set Range Composite](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_set_range_composite/task.md),
the [input limits](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_set_range_composite/info.toml),
and [RIGHTS.md](RIGHTS.md). The source repository is Apache-2.0; only task
semantics are used. The local ports and fixtures are independently authored.

## Ports

| Language | Source |
|---|---|
| C | [`c/r/range_set_range_composite.c`](../../../c/r/range_set_range_composite.c) |
| C3 | [`c3/r/range_set_range_composite.c3`](../../../c3/r/range_set_range_composite.c3) |
| C++ | [`cpp/r/range_set_range_composite.cpp`](../../../cpp/r/range_set_range_composite.cpp) |
| Elisa | [`elisa/r/range_set_range_composite.elisa`](../../../elisa/r/range_set_range_composite.elisa) |
| Mojo | [`mojo/r/range_set_range_composite.mojo`](../../../mojo/r/range_set_range_composite.mojo) |
| Nim | [`nim/r/range_set_range_composite.nim`](../../../nim/r/range_set_range_composite.nim) |
| Odin | [`odin/r/range_set_range_composite.odin`](../../../odin/r/range_set_range_composite.odin) |
| Rust | [`rust/r/range_set_range_composite.rs`](../../../rust/r/range_set_range_composite.rs) |
| V | [`v/r/range_set_range_composite.v`](../../../v/r/range_set_range_composite.v) |
| Zig | [`zig/r/range_set_range_composite.zig`](../../../zig/r/range_set_range_composite.zig) |

See [`workload.json`](workload.json), [`range_set_range_composite_oracle.py`](../../range_set_range_composite_oracle.py), and [`range_set_range_composite_verifier_oracle.py`](../../range_set_range_composite_verifier_oracle.py).
The package-local `verify_workload.py` records static checks for fixture/oracle
agreement, source metadata, and all ten port paths; it is provided for
maintainers and was not run for this package task.
