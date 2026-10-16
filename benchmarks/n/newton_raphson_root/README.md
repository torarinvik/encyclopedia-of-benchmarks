# Newton–Raphson root

This benchmark uses the real convergence path of the pinned C and Zig root-finding examples for `f(x)=x²−3` with a deterministic initial guess.

## Contract

- Uses the `float64_unary` ABI: the binary64 input is `x0` in `[1,4]`; invalid input returns `−1e300`.
- Each update uses IEEE-754 binary32 arithmetic: `x -= (x*x−3)/(2*x)`. Return when `|x*x−3| <= 1e−6`, with a maximum of 1000 updates.
- The deterministic real starting guess replaces the C source's random complex seed, and the binary32 arithmetic follows Zig's implementation. The output tolerance is `2e−5`.

Cases and outputs are in [`workload.json`](workload.json). Build and verify with:

```sh
python3 benchmarks/verify_float64_unary.py --algorithm newton_raphson_root
```
