# Powerful-number sequence by square/cube enumeration

List every powerful number through a small inclusive limit. The primary
enumerates the unique squarefree-`b` forms `a^2*b^3`, then sorts the generated
values. A separate oracle tests each integer by prime factorization.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `powerful_numbers_square_cube_enumeration`.
- Input is exactly `[limit]`, where `1<=limit<=100`.
- A positive integer is powerful if every prime divisor appears to exponent
  at least two. The value 1 is included.
- Output is `[count, n_0, ..., n_(count-1)]` as little-endian signed-i64
  words, with the powerful numbers in strictly ascending order.
- Invalid/null input returns `-1`. Null or insufficient output returns `-2`
  without writes; input validation precedes the output-capacity check.
- At most 14 values are emitted, so the maximum output is 120 bytes. Workspace
  is 512 bytes, including the staged values and sorting state.

For `limit<=100`, the cube bound gives `b<=4`; among those values only
`b=1,2,3` are squarefree. Their maximum `a` counts are 10, 3, and 1, so the
unique representation produces at most 14 values.

## Algorithm and distinction

Every powerful `n` has a unique representation `n=a^2*b^3` with squarefree
`b`: in the prime factorization, `b` contains exactly those primes whose
exponents are odd. The primary scans squarefree `b` values with `b^3<=limit`,
enumerates all positive `a` with `a^2*b^3<=limit`, and sorts the resulting
values. The independent reference scans integers in ascending order and
accepts a candidate only when direct trial factorization finds no prime
exponent below two.

This differs from [`powerful_number_summatory_sieve`](../powerful_number_summatory_sieve/README.md),
which computes a summatory arithmetic function and visits powerful numbers as
the support of its convolution using an increasing-prime/exponent DFS. This
package directly emits the ordered powerful-number sequence using the
squarefree-`b` representation.

Sources: Chan, [“Arithmetic progressions among powerful numbers”](https://cs.uwaterloo.ca/journals/JIS/VOL26/Chan/chan33.pdf),
for the unique representation, and OEIS [A001694](https://oeis.org/A001694)
for the definition. The pinned RosettaCodeData [popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
supplied title discovery only. See [RIGHTS.md](RIGHTS.md).

The hand-pinned [workload](workload.json) covers small limits, mixed square and
cube factors, the maximum bound, malformed frames, and output errors.
[INVENTORY.md](INVENTORY.md) and [inventory.json](inventory.json) list the ten
ports and package artifacts. No port or helper has been executed.

| Language | Source |
|---|---|
| C | [c/p/powerful_numbers_square_cube_enumeration.c](../../../c/p/powerful_numbers_square_cube_enumeration.c) |
| C3 | [c3/p/powerful_numbers_square_cube_enumeration.c3](../../../c3/powerful_numbers_square_cube_enumeration.c3) |
| C++ | [cpp/p/powerful_numbers_square_cube_enumeration.cpp](../../../cpp/powerful_numbers_square_cube_enumeration.cpp) |
| Elisa | [elisa/p/powerful_numbers_square_cube_enumeration.elisa](../../../elisa/p/powerful_numbers_square_cube_enumeration.elisa) |
| Mojo | [mojo/p/powerful_numbers_square_cube_enumeration.mojo](../../../mojo/p/powerful_numbers_square_cube_enumeration.mojo) |
| Nim | [nim/p/powerful_numbers_square_cube_enumeration.nim](../../../nim/powerful_numbers_square_cube_enumeration.nim) |
| Odin | [odin/p/powerful_numbers_square_cube_enumeration.odin](../../../odin/powerful_numbers_square_cube_enumeration.odin) |
| Rust | [rust/p/powerful_numbers_square_cube_enumeration.rs](../../../rust/powerful_numbers_square_cube_enumeration.rs) |
| V | [v/p/powerful_numbers_square_cube_enumeration.v](../../../v/powerful_numbers_square_cube_enumeration.v) |
| Zig | [zig/p/powerful_numbers_square_cube_enumeration.zig](../../../zig/powerful_numbers_square_cube_enumeration.zig) |
