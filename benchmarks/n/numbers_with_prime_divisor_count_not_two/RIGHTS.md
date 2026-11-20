# Rights and provenance

The Rosetta Code task title and pinned task snapshot were used to identify the
requested list semantics: positive `n < 1000` whose divisor count is prime
but not 2. The task page was not available to the browsing client; the task
scope and output requirement were supplied by the repository maintainer. No
Rosetta submission, task code, or task example was copied.

The divisor-count identity and prime factorization context follow the
CP-Algorithms article [“Number of divisors / sum of divisors”]. The bounded
primary implementation uses a clean-room divisor-count sieve, while its
independent reference counts divisor pairs. Primality uses original bounded
trial-division helpers. All package source, workload fixtures, and reference
implementations were written for this repository.

- [Pinned RosettaCodeData title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
- [Rosetta Code task page](https://rosettacode.org/wiki/Numbers_whose_count_of_divisors_is_prime)
- [CP-Algorithms: Number of divisors / sum of divisors](https://cp-algorithms.com/algebra/divisors.html)
- [CP-Algorithms: Primality tests](https://cp-algorithms.com/algebra/primality_tests.html)
