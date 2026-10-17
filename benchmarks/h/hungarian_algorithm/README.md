# Hungarian algorithm

This benchmark ports the pinned Java Hungarian algorithm for minimum-cost assignment. It preserves the source's zero-padding for rectangular matrices, row assignment results, and deterministic scan-order tie behavior while replacing the Java result object with the benchmark byte-output ABI.

## Contract

- The ABI is `i32_array_bytes_output`. Input is signed-i32 words `[rows, cols, costs...]`, with matrix costs flattened in row-major order and no count prefix. Both dimensions are 1–8, every cost is 0–1000, and the exact length is `2 + rows*cols`. The maximum valid input is 66 words; one additional word is accepted only so malformed trailing data can be rejected.
- The source pads the matrix to `max(rows, cols)` with zero costs, then runs its 1-indexed Hungarian minimizer. Output contains one zero-based original column index per input row, or `-1` when a row is assigned to a padded column, followed by the total cost of the real assignments. Output is raw little-endian signed-i32 with no count prefix. Success returns the output byte length `4*(rows+1)`, from 8 through 36 bytes.
- Preserve the source tie order: process rows in ascending order, scan candidate columns in ascending order, update a predecessor only on a strict reduced-cost improvement, and select the next column using the source's ascending scan and strict less-than comparison. This produces deterministic assignments for equal-cost matrices; it is not a general lexicographic tie rule.
- Invalid shape, arity, dimension, or cost returns `-1` before output checks. A null output pointer or capacity below `4*(rows+1)` returns `-2` without writes. Costs and dimensions are bounded so the source's signed-int potential updates and total remain safe.

The workload covers square and rectangular assignments, padded rows, tie order, maximum dimensions and cost, malformed framing/domain values, output capacity, and null pointers. See [workload.json](workload.json) and the independent [oracle](../../hungarian_algorithm_oracle.py).

The source is [TheAlgorithms/Java `HungarianAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HungarianAlgorithm.java), pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`; its algorithm method is `solve`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm hungarian_algorithm --language rust
python3 benchmarks/run_i32_array_bytes_output.py --algorithm hungarian_algorithm
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm hungarian_algorithm --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/h/hungarian_algorithm.c](../../../c/h/hungarian_algorithm.c) |
| C3 | [c3/h/hungarian_algorithm.c3](../../../c3/h/hungarian_algorithm.c3) |
| C++ | [cpp/h/hungarian_algorithm.cpp](../../../cpp/h/hungarian_algorithm.cpp) |
| Elisa | [elisa/h/hungarian_algorithm.elisa](../../../elisa/h/hungarian_algorithm.elisa) |
| Nim | [nim/h/hungarian_algorithm.nim](../../../nim/h/hungarian_algorithm.nim) |
| Odin | [odin/h/hungarian_algorithm.odin](../../../odin/h/hungarian_algorithm.odin) |
| Rust | [rust/h/hungarian_algorithm.rs](../../../rust/h/hungarian_algorithm.rs) |
| V | [v/h/hungarian_algorithm.v](../../../v/h/hungarian_algorithm.v) |
| Zig | [zig/h/hungarian_algorithm.zig](../../../zig/h/hungarian_algorithm.zig) |
