# Square-free integer predicate

## Contract

Return `1` when a positive integer has no repeated prime factor, and `0` when some prime factor occurs at least twice. Inputs 1 through 1,000,000 are supported; other values return `-1`. The exported C ABI entry point is `int64_t is_square_free(int64_t n);`.

## Source review

The pinned JavaScript source factors a positive number and checks that its factor list has no duplicates. The TypeScript source checks for repeated divisors directly. They agree on the positive-integer domain. Their edge behavior differs for nonpositive values (JavaScript throws, TypeScript throws for negatives and returns false for zero), so the benchmark limits the shared mathematical predicate to positive inputs. The repeated-factor scan preserves the result while dividing a found factor out before continuing.

The Python file with the same basename accepts a list of factor values and only checks whether the list contains duplicates; it does not accept an integer or validate that entries are prime. That operation is represented separately as `square_free_factor_list`.

## Workload

[`workload.json`](workload.json) covers 1, primes, square-free composites, repeated-prime-factor composites, and the supported-range boundary.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_square_free.c`](../../../c/i/is_square_free.c) |
| C3 | [`c3/i/is_square_free.c3`](../../../c3/i/is_square_free.c3) |
| C++ | [`cpp/i/is_square_free.cpp`](../../../cpp/i/is_square_free.cpp) |
| Elisa | [`elisa/i/is_square_free.elisa`](../../../elisa/i/is_square_free.elisa) |
| Nim | [`nim/i/is_square_free.nim`](../../../nim/i/is_square_free.nim) |
| Odin | [`odin/i/is_square_free.odin`](../../../odin/i/is_square_free.odin) |
| Rust | [`rust/i/is_square_free.rs`](../../../rust/i/is_square_free.rs) |
| V | [`v/i/is_square_free.v`](../../../v/i/is_square_free.v) |
| Zig | [`zig/i/is_square_free.zig`](../../../zig/i/is_square_free.zig) |

## TheAlgorithms references

- [JavaScript `IsSquareFree.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/IsSquareFree.js)
- [TypeScript `is_square_free.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/is_square_free.ts)
