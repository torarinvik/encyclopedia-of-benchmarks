# JavaScript friendly numbers

This benchmark preserves the behavior of the pinned JavaScript `FriendlyNumbers` predicate, including its divisor-loop boundary.

## Contract

- Input is a pair of unsigned integers `[first, second]`, each in `1..=1000`. Equal values are invalid, matching the source's explicit guard.
- For each input `n`, start the divisor sum at `n` and add each divisor `i` for `i >= 1` and `2*i < n`. Divide this sum by `n`, then return `1` if the two binary64 abundancy indexes compare equal and `0` otherwise. The integer condition preserves JavaScript's strict `i < n/2` boundary for both odd and even `n`.
- The source loop starts at zero, but `n / 0` is not an integer, so the zero iteration contributes nothing. Its strict `< n/2` bound omits `n/2` for even inputs. This makes the candidate observably different from the correct Java `friendly_number` benchmark; for example, this source reports `(2, 1)` as friendly because both computed indexes are `1.0`.
- Zero, equal, and out-of-range inputs return `-1`, the benchmark invalid-input sentinel. The source throws for zero/equal inputs; values above the bound are excluded to keep its `O(n)` scan bounded and its JavaScript integer arithmetic exact.
- Time is `O(a + b)` and auxiliary space is `O(1)`.

## Pinned source and related algorithm

The pinned [JavaScript `FriendlyNumbers.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/FriendlyNumbers.js) compares the two abundancy-index divisions directly and scans divisors with `i < number/2`. The separate Java [`friendly_number`](../friendly_number/README.md) benchmark computes the proper divisor sum through the square root and compares exact cross-products; it does not share this source quirk.

## Workload and build

[`workload.json`](workload.json) covers the source's omitted-half-divisor behavior, ordinary unequal pairs, invalid zero/equal values, and bounds. All nine ports use the shared `binary_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm friendly_numbers --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/f/friendly_numbers/rust/build.json
```
