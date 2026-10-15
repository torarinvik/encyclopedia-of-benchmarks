# Square root by Newton's method

This benchmark computes the nonnegative square root with Newton iteration. It is grouped by its algorithm name in the `s/` folder.

## Contract

- The input is a finite binary64 value in `[0, 1e300]`.
- Zero returns zero. For positive `x`, initialize the estimate to `x` when `x >= 1`, otherwise to `1`.
- Update with `next = 0.5 * estimate + 0.5 * (x / estimate)` until the next estimate is no smaller, with a limit of 1,100 iterations.
- Results are compared using relative error at most `1e-14`; zero must be exact.

All nine ports use the same Newton recurrence and standard binary64 arithmetic. The recurrence splits the sum before adding, avoiding overflow in `estimate + x / estimate` for large inputs.

## Reviewed sources

The pinned JavaScript source applies Newton's method with a fixed four-iteration default. The Python source uses a convergence tolerance and iteration cap; Ruby uses recursive Newton updates; TypeScript uses an adaptive tolerance. The shared contract keeps the common Newton method while giving each language identical input bounds, initialization, and stopping behavior. The cataloged Rust path does not resolve at its pinned revision.

- [JavaScript `SquareRoot.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/SquareRoot.js)
- [Python `square_root.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/square_root.py)
- [Ruby `square_root.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/square_root.rb)
- [TypeScript `square_root.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/square_root.ts)

## Workload and recording

`workload.json` covers zero, exact and fractional roots, values near one, and small and large magnitudes. The expected values use binary64 square-root results, with relative tolerance applied to the output so small roots receive an appropriately small error allowance.

Build with the `float64_unary` ABI family, then record with `benchmarks/run_float64_unary.py`:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm square_root --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/square_root/rust/build.json
```
