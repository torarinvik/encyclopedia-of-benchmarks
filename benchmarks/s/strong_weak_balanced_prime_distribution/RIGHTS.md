# Rights and provenance

The public [RosettaGit task-title index](https://rosettagit.org/tasks/) was
used only to discover the topic. The mathematical definitions are independently
documented by OEIS [A051634](https://oeis.org/A051634) (strong primes),
[A051635](https://oeis.org/A051635) (weak primes), and
[A006562](https://oeis.org/A006562) (balanced primes). The prime-generation
method is the Sieve of Eratosthenes as described by
[CP-Algorithms](https://cp-algorithms.com/algebra/sieve-of-eratosthenes.html);
the finite sieve ceiling follows Bertrand's postulate as stated by
[Wolfram MathWorld](https://mathworld.wolfram.com/BertrandsPostulate.html).
Sequence-data fixture cross-checks also use OEIS [A055206](https://oeis.org/A055206)
for balanced-prime counts, [A159687](https://oeis.org/A159687) for strong-prime
counts, and [A006880](https://oeis.org/A006880) for total prime counts.

This repository contains clean-room implementations of the mathematical
ideas. No RosettaGit task statement, examples, tests, submissions, source code,
or prose were copied. No CP-Algorithms code or prose was copied. The local
Miller–Rabin benchmarks implement primality-test behavior and are not duplicates
of adjacent-prime mean classification.
