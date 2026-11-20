# Rights and provenance

The algorithm is based on the mathematical definition and search method in
I. O. Angell and H. J. Godwin, “On Truncatable Primes,” *Mathematics of
Computation* 31(137) (1977), 265–267,
[DOI 10.1090/S0025-5718-1977-0427213-2](https://doi.org/10.1090/S0025-5718-1977-0427213-2).
Their article computes largest left-truncatable primes for several bases and
describes extending a valid value by prepending nonzero base digits. OEIS
[A103443](https://oeis.org/A103443/internal) independently indexes largest
left-truncatable primes by base. The [RosettaGit task-title index](https://rosettagit.org/tasks/)
was used only to discover the benchmark topic.

This package contains clean-room implementations of mathematical algorithm
ideas. No task statement, examples, tests, submissions, or source code were
copied. The local Project Euler `problem37` benchmark is not a duplicate: it
uses a fixed decimal domain, requires both left and right truncation, and sums
the qualifying primes. This package searches one-sided left truncations in
multiple bases and returns the largest qualifying value.
