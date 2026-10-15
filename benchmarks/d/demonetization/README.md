# Demonetization

Counts the ways an amount can be formed from unlimited copies of the listed denomination types, using the pinned C source's recursive include-or-skip recurrence.

## Contract

- Uses the read-only `i64_array_scalar` ABI and returns one signed 64-bit count.
- The input array packs `[amount, denomination_count, denomination_0, ...]`. Its length must equal `2 + denomination_count`.
- `amount` is in `[-30, 30]`; `denomination_count` is in `[0, 4]`; each denomination is in `[1, 30]`.
- A negative amount returns zero, matching the source's first base case.
- Amount zero returns one, even with no denominations. A positive amount with no denominations returns zero.
- Each array position is a distinct denomination type. Repeated denomination values therefore count as distinct choices, preserving the source recurrence's behavior.
- A denomination must be positive because zero or negative values can cause nonterminating recursion in the source. Invalid packed inputs return `-1` in the ports.
- The recursive recurrence is `ways(amount, k-1) + ways(amount-denomination[k-1], k)`, with negative amount returning zero, zero amount returning one, and no remaining types returning zero.

## Source semantics

The benchmark follows the pinned [TheAlgorithms C `demonetization.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/demonetization.c). Its `ways` function recursively skips the last denomination or includes one copy and keeps that denomination available. The original is an interactive program around the helper; the benchmark exposes the helper's result through a packed array contract. The bounds keep recursion and the source's `int` result practical.

## Workload and build

[`workload.json`](workload.json) includes empty and zero-amount cases, a single denomination, mixed denomination sets, repeated denomination types, and an unreachable amount. Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm demonetization --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/demonetization/rust/build.json
```

The nine implementations are in `c/d/demonetization.c`, `c3/d/demonetization.c3`, `cpp/d/demonetization.cpp`, `elisa/d/demonetization.elisa`, `nim/d/demonetization.nim`, `odin/d/demonetization.odin`, `rust/d/demonetization.rs`, `v/d/demonetization.v`, and `zig/d/demonetization.zig`.
