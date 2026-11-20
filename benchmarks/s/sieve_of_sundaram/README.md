# Sieve of Sundaram

This benchmark counts primes up to an inclusive limit using Sundaram's index
sieve. It marks the indices i + j + 2*i*j for 1 <= i <= j, maps each
unmarked index k to the odd value 2*k + 1, and accounts for prime 2
separately.

## Contract

- ABI: scalar_call; exported symbol sieve_of_sundaram.
- Input is one signed 64-bit inclusive limit in [0, 4096].
- Return the number of primes in [2, limit]; return -1 outside the input
  range.
- A fixed 2048-entry composite-flag array bounds storage. The count is one for
  prime 2 when limit >= 2, plus each unmarked eligible odd index.

## Algorithm source and distinctness

The bounded algorithm follows the standard Sundaram sieve described by
Ghidarcea and Popescu in [GPGPU and Sieve of Sundaram](https://www.scientificbulletin.upb.ro/rev_docs_arhiva/fullb1a_720372.pdf),
Algorithm 2.1, and by the [prime-sieving review](https://www.mdpi.com/1999-4893/17/4/157).
The method is attributed to V. Ramaswami Aiyar's 1934 note, “Sundaram's Sieve
for Prime Numbers,” The Mathematics Student 2(2), p. 73, as cited by the
review.
These sources describe the algorithm; no implementation code was copied.

The local [Sieve of Eratosthenes](../sieve_of_eratosthenes/README.md)
marks multiples of candidate primes starting at their squares. Sundaram marks
indices that encode odd composite factorizations through
2*(i + j + 2*i*j) + 1 = (2*i + 1)*(2*j + 1). The local Sieve of Atkin,
linear, segmented, and stream-sieve profiles also use distinct marking or
generation rules.

## References and workload

primary_oracle.py implements the indexed Sundaram marking rule.
independent_oracle.py counts candidates by direct trial division instead.
workload.json covers small limits, prime/composite boundaries, a square
boundary, the maximum supported limit, and signed invalid inputs.
verify_workload.py compares both references against the pinned cases. The
package is registered in the `scalar_call` runner and verifier.

## Language ports

| Language | Source |
| --- | --- |
| C | c/s/sieve_of_sundaram.c |
| C3 | c3/s/sieve_of_sundaram.c3 |
| C++ | cpp/s/sieve_of_sundaram.cpp |
| Elisa | elisa/s/sieve_of_sundaram.elisa |
| Mojo | mojo/s/sieve_of_sundaram.mojo |
| Nim | nim/s/sieve_of_sundaram.nim |
| Odin | odin/s/sieve_of_sundaram.odin |
| Rust | rust/s/sieve_of_sundaram.rs |
| V | v/s/sieve_of_sundaram.v |
| Zig | zig/s/sieve_of_sundaram.zig |
