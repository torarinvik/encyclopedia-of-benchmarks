# Rights and provenance

The package title and requested sequence semantics come from the Rosetta Code
task “Numbers which are the cube roots of the product of their proper
divisors.” Its mathematical sequence is cross-referenced by OEIS A111398; the
subsequence of values greater than one is OEIS A030626, the integers with
exactly eight positive divisors. A030626 records the disjoint prime-signature
families `p^7`, `p^3*q`, and `p*q*r` with the required distinctness conditions.

The primary ports use an original bounded prime-count prefix and signature
counting search. The independent reference uses a divisor-count sieve. The
Rosetta task examples, submissions, code, and prose were not copied; all
benchmark ports, oracles, metadata, and fixtures were written for this
repository.

The [task translation's published output](https://docs.zenc-lang.org/examples/rosetta/numbers-which-are-the-cube-roots-of-the-product-of-their-proper-divisors/)
labels the 500th, 5,000th, and 50,000th terms and reports 2,526, 23,118, and
223,735, respectively. Those numeric checkpoints are cited as cross-checks;
no implementation code or expressive task material was reused.

- [Rosetta Code task](https://rosettacode.org/wiki/Numbers_which_are_the_cube_roots_of_the_product_of_their_proper_divisors)
- [OEIS A111398: cube roots of proper-divisor products](https://oeis.org/A111398)
- [OEIS A030626: numbers with exactly eight divisors](https://oeis.org/A030626)
- [CP-Algorithms: number of divisors](https://cp-algorithms.com/algebra/divisors.html)
