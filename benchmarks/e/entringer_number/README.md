# Entringer number

`entringer_number` returns one cell of the Entringer triangle, the refinement of the Euler zigzag numbers by the first element of an alternating permutation.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `entringer_number`.
- Input is exactly `[n,k]` with `0 <= n <= 12` and `0 <= k <= n`.
- `E(n,k)` counts permutations of `{0,...,n}` beginning with `k` and satisfying the down-up pattern `p[0] > p[1] < p[2] > p[3] < ...`.
- Return the exact nonnegative signed-i64 count. Malformed or out-of-range input returns `-1`.
- The primary builds the triangle one row at a time: `E(0,0)=1`, `E(n,0)=0` for `n>0`, and `E(n,k)=E(n,k-1)+E(n-1,n-k)` for `1<=k<=n`.
- Time is `O(n^2)` and native workspace is at most 512 bytes (two 13-entry i64 rows and scalar locals). Every count is at most `(n+1)!`, and `13!` is below the signed-i64 limit.
- The independent reference counts alternating permutations by subset/last-element states. A direct permutation enumerator is included for tiny inputs.

## Source and distinction

The recurrence and combinatorial interpretation are described in [OI Wiki's Entringer Number article](https://oi-wiki.org/math/combinatorics/entringer/). The diagonal values are the Euler zigzag numbers listed as [OEIS A000111](https://oeis.org/A000111), and the full triangle is [OEIS A008281](https://oeis.org/A008281). Entringer numbers count alternating permutations by their first element. Eulerian numbers instead count permutations by their number of ascents or descents; the local `zigzag_conversion` benchmark rearranges characters and is unrelated.

The references and workload are original clean-room material. OI Wiki states that its article uses CC BY-SA 4.0 with additional SATA terms; this package uses only the recurrence and mathematical description, with no copied code, prose, or fixtures.

## Workload and ports

`workload.json` contains valid, boundary, and malformed scalar fixtures. `primary_oracle.py` implements the triangle recurrence. `independent_oracle.py` counts alternating permutations through subset DP and also includes a tiny direct enumerator. `verify_workload.py` and `check_inventory.py` are package-local static review artifacts; neither was executed.

- [C](../../../c/e/entringer_number.c)
- [C3](../../../c3/e/entringer_number.c3)
- [C++](../../../cpp/e/entringer_number.cpp)
- [Elisa](../../../elisa/e/entringer_number.elisa)
- [Mojo](../../../mojo/e/entringer_number.mojo)
- [Nim](../../../nim/e/entringer_number.nim)
- [Odin](../../../odin/e/entringer_number.odin)
- [Rust](../../../rust/e/entringer_number.rs)
- [V](../../../v/e/entringer_number.v)
- [Zig](../../../zig/e/entringer_number.zig)
