# New Man Shanks prime

Checks whether the recurrence term at index `n` equals a supplied expected value. Despite the source name, the method does not test primality.

## Contract

- Uses the `binary_scalar` ABI with arguments `[n, expected]`.
- Valid indices are `1..=25`; `expected` must fit signed 32-bit.
- The sequence is `a(0)=1`, `a(1)=1`, and `a(n)=2*a(n-1)+a(n-2)`. Return `1` when `a(n)==expected`, otherwise `0`.
- Return `-1` for invalid arguments. The pinned Java method throws for `n < 0`, and also fails for `n = 0` because it writes `a[1]` into an array of length one; both are mapped to the invalid sentinel.
- Index 25 yields 1,855,077,841, still within signed 32-bit. Index 26 would overflow the source's `int`, so it is outside the contract.

## Source semantics

This follows the recurrence and equality check in the pinned [TheAlgorithms Java `NewManShanksPrime.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/NewManShanksPrime.java). The source allocates an array, initializes its first two entries to one, fills it iteratively, then compares the indexed term. The ports retain the same recurrence and iteration while keeping only the previous two terms. The Java source's array storage does not affect the returned value for this bounded domain.

## Workload and build

[`workload.json`](workload.json) covers both initial terms, recurrence values, mismatches, the maximum supported index, and invalid inputs. Build and record with the `binary_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm new_man_shanks_prime --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/n/new_man_shanks_prime/rust/build.json
```

The nine implementations are in `c/n/new_man_shanks_prime.c`, `c3/n/new_man_shanks_prime.c3`, `cpp/n/new_man_shanks_prime.cpp`, `elisa/n/new_man_shanks_prime.elisa`, `nim/n/new_man_shanks_prime.nim`, `odin/n/new_man_shanks_prime.odin`, `rust/n/new_man_shanks_prime.rs`, `v/n/new_man_shanks_prime.v`, and `zig/n/new_man_shanks_prime.zig`.
