# Problem 13: Large sum

This package reproduces Project Euler Problem 13 from TheAlgorithms/Go at commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`, file `project_euler/problem_13/problem13.go`. The pinned `Problem13()` takes no arguments, sums its fixed array of one hundred 50-digit decimal strings with decimal digit addition, then returns the first ten digits of the exact sum as text.

Each port embeds the same 100 values, performs the same carry-based decimal addition, and exports the ten-digit prefix as an `i64` scalar (`5537376230` for the source dataset). The numeric ABI preserves this fixed prefix because its first digit is nonzero. The source dataset and prefix width are fixed; there is no invalid-input result.

The source operation takes no arguments. The local scalar ABI accepts one placeholder integer constrained to exactly zero and ignores it, allowing the existing `scalar_call` runner to benchmark the fixed computation.
