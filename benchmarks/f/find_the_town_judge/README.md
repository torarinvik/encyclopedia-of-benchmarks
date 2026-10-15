# Find the Town Judge

This benchmark implements TheAlgorithms/C LeetCode 997: find the person trusted by every other person who trusts nobody.

## Contract

- Input is a signed 64-bit array `[n, m, a1, b1, ..., am, bm]`, where `n` is the number of people, `m` is the trust-pair count, and each pair `a -> b` means person `a` trusts person `b`.
- `n` must be from 1 through 1,000 and `m` from 0 through 10,000. The array must contain exactly `2 + 2m` entries.
- Trust endpoints are one-based IDs in `1..n`; self-trust is invalid. Trust pairs are unique, matching the problem's input contract.
- Invalid counts, endpoints, or self-trust return `-2`. A valid input with no judge returns `-1`; otherwise the result is the judge's one-based ID. With one person and no trust edges, that person is the judge.
- Runtime is O(n + m) with O(n) degree storage.

The workload includes single-person, positive and negative cases, malformed inputs, and a 1,000-person edge chain. All nine ports use the `i64_array_scalar` ABI family.

## Upstream reference

- [TheAlgorithms/C LeetCode 997 at the pinned catalog revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/997.c)
