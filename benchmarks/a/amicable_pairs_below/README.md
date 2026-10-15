# Amicable Pairs Below a Limit

Enumerate each amicable pair whose two distinct positive members are strictly below an exclusive upper limit. The output is ordered by the smaller member, with each pair emitted once.

## Contract

- The input is a one-element signed 64-bit array containing `limit` from 1 through 8,000.
- Each pair `(a, b)` satisfies `1 < a < b < limit`, and the proper divisors of `a` sum to `b` while those of `b` sum to `a`.
- The function returns the number of pairs. It writes each pair as two unsigned 32-bit little-endian values, first `a` then `b`.
- Invalid input returns `-1`; an insufficient output buffer returns `-2` without writing output.
- With no pairs below the limit, return zero and write no bytes.

The ports use a divisor-sum sieve: each divisor is added to its proper multiples, then the completed sums are scanned for reciprocal pairs. This is O(n log n) time and O(n) scratch space. The fixed 8,000-element table keeps the working set below 64 KiB for each port.

## Workload and verification

[`workload.json`](workload.json) covers the 220/284 pair boundary, four later pair boundaries, the maximum limit, and invalid signed 64-bit inputs. [`verify_amicable_pairs_below.py`](../../verify_amicable_pairs_below.py) checks 648 limits per language against an independent multiplicative divisor-sum oracle and checks all 16 workload records through the recorder. All nine ports passed on the native host.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/amicable_pairs_below.c`](../../../c/a/amicable_pairs_below.c) |
| C3 | [`c3/a/amicable_pairs_below.c3`](../../../c3/a/amicable_pairs_below.c3) |
| C++ | [`cpp/a/amicable_pairs_below.cpp`](../../../cpp/a/amicable_pairs_below.cpp) |
| Elisa | [`elisa/a/amicable_pairs_below.elisa`](../../../elisa/a/amicable_pairs_below.elisa) |
| Nim | [`nim/a/amicable_pairs_below.nim`](../../../nim/a/amicable_pairs_below.nim) |
| Odin | [`odin/a/amicable_pairs_below.odin`](../../../odin/a/amicable_pairs_below.odin) |
| Rust | [`rust/a/amicable_pairs_below.rs`](../../../rust/a/amicable_pairs_below.rs) |
| V | [`v/a/amicable_pairs_below.v`](../../../v/a/amicable_pairs_below.v) |
| Zig | [`zig/a/amicable_pairs_below.zig`](../../../zig/a/amicable_pairs_below.zig) |

## TheAlgorithms references

- [Java `AmicableNumber.findAllInRange`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AmicableNumber.java) enumerates pairs in an inclusive interval by checking each pair.
- [Julia `amicable_pairs`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/amicable_numbers.jl) and [Rust `amicable_pairs_under_n`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/amicable_numbers.rs) use a divisor-sum sieve. The shared contract standardizes the limit as exclusive and emits an empty result as count zero.

The Dart and R files with the same normalized filename expose pair predicates; those functions are reviewed under [`amicable_number`](../amicable_number/README.md). The Java source also has a predicate, while its range method belongs here.
