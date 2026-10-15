# Nilakantha pi approximation

Computes a finite prefix of the Nilakantha series for pi.

## Contract

- Uses the unary binary64 ABI: `double pi_nilakantha(double iterations)`.
- Accepted inputs are exactly integral binary64 values from 0 through 500. Other values return `-1.0` as the benchmark's invalid-input sentinel.
- Starts at `pi = 3.0` and `divCounter = 2`. Each iteration adds `4.0 / (d*(d+1)*(d+2))` when its zero-based index is even and subtracts it when odd, then increases `d` by 2.
- The denominator is formed with signed 32-bit integer arithmetic, as in the Java source. At the upper bound its largest value is `1000*1001*1002`, which fits signed 32-bit.
- Results use binary64; comparisons allow absolute and relative tolerance `1e-12`.

## Source semantics

This follows pinned [TheAlgorithms Java `PiNilakantha.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PiNilakantha.java). Its `calculatePi(int)` accepts 0 through 500 inclusive, returns 3 for zero iterations, and performs the alternating series in the order documented above. The benchmark ABI passes an integer-valued double because the repository's existing scalar floating-point ABI is unary binary64. Fractional and out-of-range inputs are outside the source domain and map to the documented sentinel.

## Workload and build

[`workload.json`](workload.json) covers zero iterations, individual terms, a short prefix, and the source's maximum iteration count, plus invalid ABI inputs.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm pi_nilakantha --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/p/pi_nilakantha/rust/build.json
```

The implementations are in `c/p/pi_nilakantha.c`, `c3/p/pi_nilakantha.c3`, `cpp/p/pi_nilakantha.cpp`, `elisa/p/pi_nilakantha.elisa`, `nim/p/pi_nilakantha.nim`, `odin/p/pi_nilakantha.odin`, `rust/p/pi_nilakantha.rs`, `v/p/pi_nilakantha.v`, and `zig/p/pi_nilakantha.zig`.
