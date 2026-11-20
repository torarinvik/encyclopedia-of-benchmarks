# Reservation: classical Eulerian number by descent count

**Status:** Ten-language package and central `i64_array_scalar` suite
integration are complete. The reservation was entered in
`benchmarks/ALGORITHM_EXPANSION_COVERAGE.md` before package files were created.
No programs, checkers, tests, builds, compilers, or benchmarks have been run.

## Contract

Use the `i64_array_scalar` ABI with input `[n,k]`. Accept `0<=n<=20`; for
`n=0`, only `k=0` is valid, and for `n>0`, accept `0<=k<n`. Return the
Eulerian number `A(n,k)`, the number of permutations of `[n]` with exactly
`k` descents. Invalid/null input or framing returns `-1`. The maximum valid
input has two words and the maximum parseable frame has three words. Every
valid result is at most `20!`, within signed 64-bit range.

## Methods and distinction

Primary method: build the Eulerian row using `A(0,0)=1` and
`A(n,k)=(k+1)A(n-1,k)+(n-k)A(n-1,k-1)`, treating out-of-range entries as
zero. Use two rows, `O(n^2)` time and `O(n)` auxiliary space.

Independent reference: for `n>=1`, evaluate
`A(n,k)=sum(j=0..k+1, (-1)^j * binom(n+1,j) * (k+1-j)^n)` with arbitrary-
precision intermediates. Return `A(0,0)=1` directly; the formula is not used at
`n=0`. This reference does not use the row recurrence.

This counts permutations by descents. It is distinct from
[`entringer_number`](../entringer_number/README.md), which counts alternating
permutations by first element, and from Eulerian graph paths/circuits.

## Provenance and rights

The discovery heading is OI Wiki's “Eulerian Number” under combinatorics.
Method context is its [article](https://oi-wiki.org/math/combinatorics/eulerian/),
the [OEIS Eulerian triangle A008292](https://oeis.org/A008292), and Stanley,
*Enumerative Combinatorics*, Volume 1, §1.4. OI Wiki's notice gives
[CC BY-SA 4.0 and SATA](https://oi-wiki.org/intro/faq/). Only the mathematical
algorithm idea and standard definition are used; no source code, prose,
examples, or tests are copied.

The package provides ten clean-room native ports, two Python references,
bounded fixtures, rights and inventory metadata, and package-local static
workload and inventory checker sources. The suite runner and verifier now
validate and register the profile.
