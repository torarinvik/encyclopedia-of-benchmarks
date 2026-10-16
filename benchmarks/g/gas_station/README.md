# Gas station circuit start

Given gas available at each station and the gas cost to reach the next station, return a start index that permits one full trip around the circuit, or `-1` if the total available gas is insufficient.

## Contract

- Pack signed 64-bit integers as `[n, gas[0..n], cost[0..n]]`, with exactly `2*n + 1` values.
- `n` is in `0..=128`; each gas and cost value is in `0..=1,000,000`.
- Visit stations in input order. Accumulate `net = gas[i] - cost[i]`; when the running net becomes negative, set the candidate start to `i + 1` and reset the running net to zero. After the scan, return `-1` if total net is negative; otherwise return the candidate start. For `n=0`, return `0`.
- Invalid packing or out-of-domain values return `-2`. A valid but infeasible route returns `-1`.

## Source and variants

Both pinned Python implementations use this greedy candidate-start rule:

- [data_structures/arrays/gas_station.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/gas_station.py), `can_complete_circuit`
- [greedy_methods/gas_station.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/gas_station.py), `can_complete_journey`

The first source initializes its feasibility accumulator with the sum of all net gains and then adds every net gain again during the scan. This doubles the total but does not change its sign, so it produces the same feasibility decision as the second source. The benchmark uses the common net total. [`workload.json`](workload.json) covers the pinned examples, a start reset, a zero-total feasible route, empty input, no solution, and invalid packing/domain values.

Verify all nine ports against the greedy oracle with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms gas_station
```
