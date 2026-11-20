# Batched bounded-range GCD with linear preprocessing

This profile compares a batched GCD method that preprocesses the value range
once and then answers each pair with a fixed number of table lookups. It
implements the method proposed in Library Checker issue #1380; the issue is
used only as an idea index, and all code, fixtures, contracts, and wording here
are original.

## Contract

The `i64_array_bytes_output` entry point is
`batch_gcd_small_range_precomputed`. Input is `[V,Q,(a,b)*Q]`, with
`1<=V<=64`, `0<=Q<=64`, and `0<=a,b<=V`. The function returns the number of
bytes written and emits one nonnegative signed little-endian i64 GCD for each
pair. A zero operand is supported, including `(0,0)`.

The valid input length is at most 130 signed-i64 words; 131 words are
parseable for the one-extra-word rejection case. The maximum output is 512
bytes. Malformed framing, out-of-range values, and null input return `-1`.
After validating the complete input, a null output pointer or capacity below
`8*Q` returns `-2` without writing.

## Method and bounds

An Euler linear sieve records the least prime factor of every value through
`V`. Each positive value is recursively represented as a product of three
factors. When `x=p*y` for the least prime factor `p`, take the representation
of `y`, multiply its smallest factor by `p`, and sort the three factors. The
representation invariant is that each factor is either at most `sqrt(x)` or
is prime. A triangular table stores `gcd(a,r)` for `0<=r<a<=floor(sqrt(V))`,
using `gcd(a,r)=gcd(r,a mod r)`; its entries are filled in constant time each.

For a query `(x,y)`, zero is handled directly. Otherwise, consume the three
factors of `x` in turn. A factor at most `sqrt(V)` uses one table lookup after
reducing the current remainder modulo that factor. A larger factor is prime,
so its contribution is either itself or one according to divisibility. The
three contributions multiply to `gcd(x,y)`.

The linear sieve, factor representations, and triangular GCD table take
`O(V)` preprocessing time and `O(V)` storage. Each pair takes `O(1)` word
operations, so `Q` queries take `O(Q)` time after preprocessing. The complete
call therefore takes `O(V+Q)` time and `O(V)` auxiliary storage. The
independent reference applies ordinary Euclid separately to each pair.

This differs from [`gcd`](../gcd/README.md), which applies Euclid to each
individual pair, and [`bitwise_gcd`](../bitwise_gcd/README.md), which applies
Stein's binary algorithm per pair. [`gcd_of_n_numbers`](../gcd_of_n_numbers/README.md)
folds GCD across one list; it does not preprocess a bounded value domain to
answer many independent pair queries in constant time.

## Source and rights

Discovery: [Library Checker proposal #1380, “O(V)-O(1) gcd”](https://github.com/yosupo06/library-checker-problems/issues/1380).
The proposal is a community idea index. Its algorithm description was
independently translated into this bounded contract; no issue text, source
code, tests, or examples were reused. See [`RIGHTS.md`](RIGHTS.md).

## Ports and package metadata

| Language | Source |
|---|---|
| C | [`c/b/batch_gcd_small_range_precomputed.c`](../../../c/b/batch_gcd_small_range_precomputed.c) |
| C3 | [`c3/b/batch_gcd_small_range_precomputed.c3`](../../../c3/b/batch_gcd_small_range_precomputed.c3) |
| C++ | [`cpp/b/batch_gcd_small_range_precomputed.cpp`](../../../cpp/b/batch_gcd_small_range_precomputed.cpp) |
| Elisa | [`elisa/b/batch_gcd_small_range_precomputed.elisa`](../../../elisa/b/batch_gcd_small_range_precomputed.elisa) |
| Mojo | [`mojo/b/batch_gcd_small_range_precomputed.mojo`](../../../mojo/b/batch_gcd_small_range_precomputed.mojo) |
| Nim | [`nim/b/batch_gcd_small_range_precomputed.nim`](../../../nim/b/batch_gcd_small_range_precomputed.nim) |
| Odin | [`odin/b/batch_gcd_small_range_precomputed.odin`](../../../odin/b/batch_gcd_small_range_precomputed.odin) |
| Rust | [`rust/b/batch_gcd_small_range_precomputed.rs`](../../../rust/b/batch_gcd_small_range_precomputed.rs) |
| V | [`v/b/batch_gcd_small_range_precomputed.v`](../../../v/b/batch_gcd_small_range_precomputed.v) |
| Zig | [`zig/b/batch_gcd_small_range_precomputed.zig`](../../../zig/b/batch_gcd_small_range_precomputed.zig) |

The ten native ports are also listed in [`INVENTORY.md`](INVENTORY.md). The
[workload](workload.json), [primary reference](primary_oracle.py),
[independent Euclidean reference](independent_oracle.py), and
[`verify_workload.py`](verify_workload.py) describe and statically inventory
the bounded profile. The package is registered in the `i64_array_bytes_output`
suite and the repository catalog.
