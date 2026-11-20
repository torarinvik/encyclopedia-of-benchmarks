# Rights and provenance

The division operation and arbitrary-precision task family are attributed to
[Library Checker](https://github.com/yosupo06/library-checker-problems), whose
problem repository is licensed under Apache-2.0. The official operation is
specified in
[`division_of_big_integers/task.md`](https://github.com/yosupo06/library-checker-problems/blob/master/big_integer/division_of_big_integers/task.md).

The limb-division method is attributed to Knuth, *The Art of Computer
Programming*, Volume 2, §4.3.1, Algorithm D; a descriptive algorithm reference
is provided by the [FLINT integer-division documentation](https://fredrikj.net/fdoc/html/algorithms/integers/division.html).
This package uses only the mathematical operation and algorithm description.
All implementations, workload fixtures, and oracle code are independently
written. No problem statement prose, upstream implementation, official tests,
or official fixtures are included. The decimal byte ABI, limb radix, 64-digit
bound, output encoding, and validation rules are local benchmark choices.
