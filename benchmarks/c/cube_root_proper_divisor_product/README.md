# Cube root of proper-divisor product sequence

## Contract

The exported `cube_root_proper_divisor_product` scalar function accepts one
signed 64-bit integer `[k]`, the **1-based** sequence index, with
`1 <= k <= 50000`. It returns `1` at index 1; subsequent terms are the
increasing integers `n>1` with exactly eight positive divisors. Invalid input
returns `-1`. The bounded valid result is at most 600,000. ABI:
`i64_array_scalar`, symbol `cube_root_proper_divisor_product(i64*,length)`.

For `n>1`, the product of all positive divisors is `n^(tau(n)/2)`, so the
product of proper divisors is `n^(tau(n)/2-1)`. Requiring `n` itself to be its
integer cube root gives `n^3=n^(tau(n)/2-1)`, hence `tau(n)=8`. The first term
is separately `1`, since its empty proper-divisor product is 1.

## Methods and bounds

The primary implementations build a prime-count prefix table through 600,000.
They count `tau(n)=8` values at a candidate bound using the disjoint
signatures `p^7`, `p^3*q` with `p!=q`, and `p*q*r` with pairwise distinct
primes. A lower-bound binary search finds the first value where the count
reaches `k-1`. The 600,001-entry `uint32` prefix table uses 2,400,004 bytes.
The workspace ledger reserves at most 124 additional bytes for scalar loop,
search, and argument state, for a total cap of 2,400,128 bytes; no quotient
array is stored. Signature products are bounded using division checks before
multiplication.

The independent reference increments a divisor-count table for every
multiple of each divisor through 600,000, then scans for the requested
`tau(n)=8` term. This differs from the prime-signature counting method.

The task displays the first 50 terms. Workload fixtures cover the initial
terms and the published 500th, 5,000th, and 50,000th checkpoints. The latter
is the bounded stretch target:
the pinned outputs are 2,526, 23,118, and 223,735 at those respective
indexes, all below the 600,000 search cap.

OEIS [A111398](https://oeis.org/A111398) defines the sequence as 1 followed
by numbers with eight divisors; [A030626](https://oeis.org/A030626) gives the
three prime-signature families. The Rosetta Code task is the discovery and
sequence-semantics source. The [task translation's published
output](https://docs.zenc-lang.org/examples/rosetta/numbers-which-are-the-cube-roots-of-the-product-of-their-proper-divisors/)
labels the three checkpoints and reports 2,526, 23,118, and 223,735. These
numeric outputs are cross-checks; implementations and fixture construction
are clean-room.

## Workload and inventory

[`workload.json`](workload.json) covers the special first term, the initial
signature families, the 1-based offset, the maximum valid index, malformed
frames, and signed 64-bit invalid values. The primary signature-search and
independent divisor-sieve oracles and static inventory helpers are listed in
[`INVENTORY.md`](INVENTORY.md). These helpers have not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/cube_root_proper_divisor_product.c`](../../../c/cube_root_proper_divisor_product.c) |
| C3 | [`c3/c/cube_root_proper_divisor_product.c3`](../../../c3/cube_root_proper_divisor_product.c3) |
| C++ | [`cpp/c/cube_root_proper_divisor_product.cpp`](../../../cpp/c/cube_root_proper_divisor_product.cpp) |
| Elisa | [`elisa/c/cube_root_proper_divisor_product.elisa`](../../../elisa/c/cube_root_proper_divisor_product.elisa) |
| Mojo | [`mojo/c/cube_root_proper_divisor_product.mojo`](../../../mojo/c/cube_root_proper_divisor_product.mojo) |
| Nim | [`nim/c/cube_root_proper_divisor_product.nim`](../../../nim/c/cube_root_proper_divisor_product.nim) |
| Odin | [`odin/c/cube_root_proper_divisor_product.odin`](../../../odin/c/cube_root_proper_divisor_product.odin) |
| Rust | [`rust/c/cube_root_proper_divisor_product.rs`](../../../rust/c/cube_root_proper_divisor_product.rs) |
| V | [`v/c/cube_root_proper_divisor_product.v`](../../../v/c/cube_root_proper_divisor_product.v) |
| Zig | [`zig/c/cube_root_proper_divisor_product.zig`](../../../zig/c/cube_root_proper_divisor_product.zig) |
