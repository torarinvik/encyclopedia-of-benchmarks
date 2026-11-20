# Rights and provenance

The algorithm idea is based on Sabit Zahin's
[`distinct_subarray_aggregates.cpp`](https://github.com/sgtlaugh/algovault/blob/78cdaf62b70ca0622e8887d2e357fb90b91d449c/code_library/data_structures/distinct_subarray_aggregates.cpp)
in Algovault, an MIT-licensed repository. The source description informed the
suffix-range compression method and its use with GCD, bitwise OR, and bitwise
AND.

All local ports, references, contract text, fixtures, and documentation were
written independently. No upstream implementation code, tests, examples,
comments, or prose were copied. The operation selector keeps the three
aggregate modes in one benchmark because they share the same compression
algorithm.
