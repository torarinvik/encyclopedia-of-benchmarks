# Transform invariants — draft research

Use the composition convention in the package README. For a representation
`rho`, define the transform block as `F_rho = sum_g f(g) rho(g)`. This choice
implies that convolution transforms to `A_rho B_rho`, in that order. A correct
implementation must not reverse these products: permutation composition is not
commutative. The explicit S3 probes distinguish the two orders.

For level `k`, let `H = S_(k-1)` fix the last position. For each image `j` of
that position, choose a transposition `t_j` taking `k-1` to `j` (the identity
when `j = k-1`). Every `g` has a unique factorization `g = t_j h` with
`h` in `H`. Therefore each forward block is a sum over `j` of `rho(t_j)`
times a subgroup transform of the function restricted to that coset. In a
branching-compatible seminormal basis, restricting a block to `H` splits into
the blocks indexed by deleting one box from the corresponding partition.
Sparse adjacent-transposition actions can form `rho(t_j)` without treating
each full group element as an unrelated dense matrix.

The forward research draft implements this recurrence by placing each smaller
block in its parent restriction block, then left-multiplying by the sparse
adjacent-generator word for the coset transposition. It checks that the
restricted tableau order matches the smaller plan. Its memory use, generator
orientation, and scaling have not been verified.

Over the proposed field, the characteristic exceeds nine and does not divide
`n!`. Under a complete set of irreducible representations, the mathematical
inverse is the sum over blocks of `dimension * trace(F_rho rho(g^-1)) / n!`.
This formula fixes normalization but evaluating it separately for each `g`
would lose the intended factorial-times-polynomial performance. A production
inverse must exploit the subgroup-chain factorization and an appropriate dual
or transpose recurrence. An [inverse research draft](inverse_reference.py)
uses the transpose of the forward map, weighted by the seminormal invariant
diagonal form and block dimensions; its construction and normalization remain
unverified. Each local generator is an involution, so its diagonal form obeys
`S^T D = D S`. The inverse pairs a block entry `(r,c)` with weight
`dimension * D[r] / (n! * D[c])` before transposing the forward recurrence.
The [seminormal reference scaffold](seminormal_reference.py) drafts a sparse
column convention using content differences and the tableau with positive
distance to orient each pair. It orders tableaux by their cells from last to
first so that tableaux with the same removed corner are contiguous, recursively
down the subgroup chain. Its generator relations, branching order, and
compatibility with the transform convention need verification before it can
support production code. Do not infer that a complex orthogonal representation
can be copied directly into the prime field.

The subgroup restriction and seminormal approach are described in
[Rockmore's Fourier inversion paper](https://math.utoledo.edu/~dgajews/p31-rockmore.pdf)
and [Maslen and Rockmore's overview](https://library2.msri.org/books/Book46/files/11maslen.pdf).
This note is independently written from the mathematical method. It is a
design draft, not evidence of an implemented or verified transform.
