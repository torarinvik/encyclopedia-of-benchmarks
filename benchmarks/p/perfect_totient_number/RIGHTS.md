# Rights and provenance

This package contains clean-room implementations of the bounded perfect-
totient predicate. The [RosettaGit task-title index](https://rosettagit.org/tasks/)
was used only to discover the candidate title; no task statement, example,
test, submission, or source code was used.

The algorithm definition and mathematical context are attributed to Douglas E.
Iannucci, Deng Moujie, and Graeme L. Cohen, “On Perfect Totient Numbers,”
*Journal of Integer Sequences* 6 (2003), article 03.4.5:

- https://cs.uwaterloo.ca/journals/JIS/VOL6/Cohen2/cohen50.pdf

OEIS A082897 provides an independent sequence cross-reference:

- https://oeis.org/A082897

The paper and OEIS entry are references, not sources of copied implementation
code. The primary reference here computes Euler's totient by distinct-prime
factorization; the independent reference counts coprime residues directly.
All benchmark source files and oracle code in this package were written for
this repository.
