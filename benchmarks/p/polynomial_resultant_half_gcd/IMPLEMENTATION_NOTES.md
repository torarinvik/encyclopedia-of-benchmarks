# Half-GCD implementation invariants

The C++ scaffold represents zero as an empty coefficient vector and all other
polynomials in ascending order with a nonzero last coefficient. Its matrices
act forward on a column pair. Consequently, a division `a = q*b + r` has
forward matrix `[[0,1],[1,-q]]`, and composing successive reductions places
the later matrix on the left. A recursive implementation must preserve this
orientation consistently when lifting from high coefficient slices.

At the entry to a half-GCD reduction, normalize the degree order so the first
polynomial has strictly larger degree. The returned transformed pair must be
consecutive Euclidean remainders straddling the selected half-degree threshold;
the recorded matrix must map the original full pair to those full remainders.
Identity is valid when the second degree is already below the threshold.

The unexecuted C++ `half_reduce` draft builds the forward transformation and
optionally records each Euclidean quotient's degree and leading coefficient.
Its cutoff, high-part lifting, recursive degree boundaries, and quotient
sequence still require verification.
The separate `matrix_reference.py` draft supplies schoolbook polynomial
arithmetic and both direct and recursive matrix reductions for future
differential checks; its low configurable cutoff exposes recursion on small
inputs. This reference shares the recursive degree decomposition, so comparing
its recursive and direct paths does not establish resultant-factor correctness.

The resultant cannot be recovered solely from that matrix determinant. Each
Euclidean step contributes a leading-coefficient power and a parity sign. A
recursive high-part call operates on truncated polynomials: it must carry the
degree offset and defer the contribution involving its final truncated
remainder until lifting establishes that remainder's true degree and leading
coefficient. Zero remainders and constant divisors require explicit handling.

The C++ kernel draft instead records quotient heads in order. Given the current
remainder degree and leading coefficient, the next quotient determines the
next remainder's degree by subtraction and leading coefficient by division.
The final remainder's degree comes from applying the matrix to the full input,
which avoids treating the truncated boundary remainder as complete. This is a
draft of the alternative quotient-sequence approach described in the
[computer algebra notes](https://perso.ens-lyon.fr/bruno.salvy/data/poly-CA.pdf);
the reconstruction and boundary cases still need independent verification.

The two small references provide independent checks of the eventual factor
tracking: direct remainder recurrence and Sylvester determinant. In addition to
their current hand cases, future verification should include long degree drops,
equal initial degrees, common factors, nonmonic divisors, and cases crossing
the recursive and NTT cutoffs. All of these are future checks; nothing has
been compiled or executed.

`structured_cases.py` drafts larger monomial-divisor and common-factor cases
with closed-form expected results, including degrees near 64 and the maximum
input length. Its maximum-size case is deliberately not sent to the quadratic
or determinant oracles. The verifier wiring is present but has not been run.
It also includes a long chain with consecutive monic divisors and known
resultant 3, an odd-degree swap-sign pair, and a parseable extra-word case.
The verifier drafts an explicit lifted-boundary case whose high slices divide
exactly while the full first remainder is `1-x`, so truncated zero cannot be
treated as a true zero remainder.
The measured workload includes `x^65+x^32+1` against `x^64`, whose resultant
is 1. After the first division its remainder is `x^32+1`; the next division
uses a 33-coefficient quotient and divisor, crossing the multiplication
cutoff as well as the recursive cutoff. The fixture validator uses the direct
remainder reference for this case and keeps the determinant reference's
degree-sum limit at 32.

The Elisa draft has a specialized left-composition by a Euclidean step: it
copies the previous bottom row to the new top row and subtracts each quotient
product from the corresponding previous top entry. Its input matrix, output
matrix, polynomial product, and NTT scratch must be disjoint. This reduces the
temporary matrix storage needed by the eventual recursive workspace, but that
workspace's maximum-size bounds have not yet been proven. A recursive draft
now partitions each caller-owned frame into three matrices and four polynomial
buffers, carries quotient heads, and rejects insufficient frame storage. It
shares separately supplied arithmetic scratch across sequential calls. The
frame sizing, recursion, aliasing, and total capacity still require review.
The separate `rp_factors` helper reconstructs one lifted batch's scalar factor
and checks quotient degree and coefficient invariants; the caller must handle
zero remainders and constant divisors. This helper is also unverified.
`rp_resultant_work` connects the batches and handles equal degrees, ordinary
divisions, constant divisors, and zero remainders using separate caller-owned
buffers. It expects the input pair already ordered by degree; the drafted ABI
wrapper accounts for the resultant sign when swapping inputs. Its allocation
uses a frame budget of `192*(max_count+2)` i64 slots and disjoint polynomial,
matrix and transform views. Conditional on the half-GCD degree invariants, a
nontrivial child has first-input length at most `floor(n/2)+1`. Along a live
call chain, writing `t=n-2` gives `t_child <= floor(t/2)`, so the sum of `t`
is at most twice its initial value. Every nontrivial call has `n>=3`, hence
there are at most `n_initial-2` such calls. Each frame uses `32*(n+1)`
slots, giving the loose bound `160*(n_initial-2)` slots, below the allocated
budget. This is a static argument conditional on the reduction invariants;
all view capacities, aliasing, and maximum-case behavior still need
independent verification.

The C++ port is split across three local headers. The draft build manifest
records their paths and hashes as `source_dependencies` in addition to the
entry-point hash. The scalar runner requires those dependencies, compares
their current hashes to the manifest, and includes them in output records;
the verifier checks that the records retain the manifest entries. This
provenance wiring has not been executed.
