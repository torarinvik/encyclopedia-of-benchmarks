# Assembly Line Scheduling

This benchmark computes the minimum time to process one product through two assembly lines with one station per stage. At each station, the product may stay on its current line or switch to the other line and pay that transition's cost.

## Contract

- The `i64_array_bytes_output` input is `[n, a0[n], a1[n], t0[n-1], t1[n-1], e0, e1, x0, x1]`.
- Require 1–64 stations and nonnegative service, transfer, entry, and exit times no greater than 1,000.
- `t0[k]` is the source `t[0][k+1]` cost to switch from line 0 to line 1 before station `k+1`; `t1[k]` is `t[1][k+1]`, the cost to switch from line 1 to line 0. The source's transfer entries at station 0 are unused.
- The result is one signed 32-bit minimum total time, encoded little-endian. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.
- The recurrence uses O(n) time and O(1) auxiliary space. The cost bounds keep all intermediate values within signed 32-bit range.

Let `f0` and `f1` be the minimum costs after each station. The first station costs are `e0 + a0[0]` and `e1 + a1[0]`. For later stations, the algorithm takes the minimum of staying on the current line and switching from the other line, then adds the destination station's service time. It adds the selected line's exit cost after the final station.

## Source and workload

The benchmark follows the two-line dynamic-programming recurrence in the pinned [TheAlgorithms/Kotlin `AssemblyLineScheduling.kt`](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/AssemblyLineScheduling.kt). Its Kotlin `Int` result is safe for the bounded contract above. [`workload.json`](workload.json) covers one station, a four-station example, beneficial switching, a stay-on-one-line optimum, zero costs, the station limit, malformed inputs, and short output capacity.

The shared byte-output runner validates the flattened input and computes the same recurrence as an independent source oracle. It returns `-2` when the declared output capacity is less than four bytes.

Build with the shared byte-output ABI and function symbol `assembly_line_scheduling`:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm assembly_line_scheduling --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm assembly_line_scheduling
```
