# Lucky number

This benchmark preserves the pinned Java method's iterative predicate. It is not a standard lucky-number sieve or a primality test.

## Contract

- Uses the `scalar` ABI with one signed integer input.
- Valid inputs are positive values from 1 through 1,000,000 inclusive.
- Returns `1` when the method completes its rank loop and `0` when it finds a divisible rank; invalid ABI values return `-1`.
- The bound keeps the input within positive signed-int32 and gives a small, bounded loop.

## Source semantics

The implementation follows pinned [TheAlgorithms Java `LuckyNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/LuckyNumber.java). Starting with `counter = 2` and `position = input`, it checks `position % counter`; if divisible it returns false, otherwise it subtracts integer `position / counter` and increments `counter` by exactly one. It returns true when the counter passes the updated position.

The source calls this a lucky-number check, but its loop does not update the counter to the next surviving lucky value as the standard sieve does. Therefore its results differ from standard lucky-number membership: for example, this pinned method returns false for `15`, although 15 is a standard lucky number. This benchmark preserves the pinned loop exactly and measures that behavior.

## Workload and build

[`workload.json`](workload.json) includes source-predicate examples, the `15` divergence, the supported upper bound, and invalid inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm lucky_number --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/l/lucky_number/rust/build.json
```

The nine implementations are in `c/l/lucky_number.c`, `c3/l/lucky_number.c3`, `cpp/l/lucky_number.cpp`, `elisa/l/lucky_number.elisa`, `nim/l/lucky_number.nim`, `odin/l/lucky_number.odin`, `rust/l/lucky_number.rs`, `v/l/lucky_number.v`, and `zig/l/lucky_number.zig`.
