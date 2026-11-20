# Rights and provenance

The Lentz ratio recurrence is described in the numerical-method literature and
is explicitly named as an alternative to Steed's method in NIST DLMF
[§3.10(iii)](https://dlmf.nist.gov/3.10.iii). The detailed recurrence and
finite precision zero-shift discussion are given by Thompson and Barnett,
“Coulomb and Bessel Functions of Complex Arguments and Order,” Appendix III,
*Journal of Computational Physics* 64 (1986), 490–509. This benchmark uses an
exact finite-field profile and rejects zero divisors; the source's tiny-value
regularization is not imported into the field contract.

No source code, comments, prose, examples, or tests are copied. The finite
field adaptation, references, fixtures, workload, and native ports are
independently authored. The package makes no numerical convergence or
roundoff-stability claim for the finite-field trace.
