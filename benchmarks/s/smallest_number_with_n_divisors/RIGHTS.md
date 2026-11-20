# Rights and provenance

The task is the mathematical sequence of least positive integers with a given
number of divisors, catalogued as [OEIS A005179](https://oeis.org/A005179) and
described by the [Rosetta Code task](https://rosettacode.org/wiki/Sequence:_smallest_number_with_exactly_n_divisors).
The search uses the standard identity `tau(product(p_i^e_i)) = product(e_i+1)`
and the fact that the least representative uses ascending primes with
nonincreasing exponents. These mathematical ideas are not claimed as original.

No source code, task examples, prose, or fixtures were copied. The bounded
`[d, limit]` contract, ten implementations, references, workload, and
documentation are independently authored. Rosetta Code identifies its page
content as GFDL-1.3-or-later; this package does not reproduce that content.
