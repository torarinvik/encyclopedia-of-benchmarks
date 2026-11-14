# Ordered pairwise difference product

For field elements `a_0, ..., a_(n-1)`, compute
`product_(i<j)(a_i-a_j) mod 998244353`. This is a Vandermonde product, not
the local [`polynomial_interpolation`](../../p/polynomial_interpolation/README.md)
operation or the general [`multipoint_evaluation`](../../m/multipoint_evaluation/README.md)
operation. Repeated elements yield zero; rearranging elements changes the
sign according to the permutation parity.

## Draft contract

The intended `i64_array_scalar` ABI input is `[n, a_0, ..., a_(n-1)]`, with
`0 <= n <= 65536`, exactly `n` canonical field elements in `0..998244352`,
and a result in the same range. The empty and singleton products are 1.
Malformed input returns `-1`. The bound fits the scalar harness's maximum
input length and leaves space for the radix-2 transforms needed here.

The intended algorithm recursively splits the ordered input. For each pair
of halves, form the monic polynomial whose roots are the left elements and
evaluate it at the right elements using a polynomial product/remainder tree.
Multiply those values with the two recursive products, correcting the sign
for the number of cross-half pairs. Polynomial multiplication uses the NTT
over the field. The target is O(M(n) log² n) time and O(n log n) working
space with transform multiplication cost M(n) = O(n log n); exact bounds
depend on the chosen tree implementation. A direct O(n²) pair loop is
appropriate only as a small-case oracle, not as the benchmark kernel.

## Provenance and status

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1417)
is an idea index for this operation. The contract and implementation are
independently written; no issue text, code, or test data are reused.

This package is reserved and in progress. The [C++](../../../cpp/d/difference_product.cpp)
and [Rust](../../../rust/d/difference_product.rs) drafts contain the recursive
kernel, finite-field transforms, polynomial multiplication, series inversion,
remainders, and multipoint trees; [Nim](../../../nim/d/difference_product.nim)
and [V](../../../v/d/difference_product.v) drafts use the same scalable
method. A [C draft](../../../c/d/difference_product.c) also implements the
full tree and frees intermediate allocations; it returns `-1` if allocation
fails. A [Mojo draft](../../../mojo/d/difference_product.mojo) also implements
the full tree. A separate direct-pair oracle is suitable for small inputs.
The [Odin](../../../odin/d/difference_product.odin) and
[Zig](../../../zig/d/difference_product.zig) drafts also include the complete
tree and bounded interface. The [C3 draft](../../../c3/d/difference_product.c3)
also includes the complete tree and bounded interface, returning `-1` if an
allocation fails. The [Elisa draft](../../../elisa/d/difference_product.elisa)
implements the tree using views over a heap-backed coefficient arena and fixed
metadata arrays; the latter occupy roughly 5 MiB on a 64-bit platform. Its
allocation failure also returns `-1`. Fixtures and scalar-suite registration
are present, including generated cases across tree and transform boundaries.
Nothing has been compiled or executed, and workspace bounds, stack
requirements and output remain unverified.
