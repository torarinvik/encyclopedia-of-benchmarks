# Stock Span Problem

For each price, return the number of consecutive days ending on that day whose prices were no greater than the current price. The Java and Python sources use an index stack and remove earlier prices less than or equal to the current one.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[count, price0, ..., price(count-1)]` with exact length `count + 1`.
- `count` is in `1..=64`. The nonempty domain follows the Python routine, which initializes its first span at index zero.
- Each price must fit signed 32-bit, matching the Java `int[]` input type.
- Output is one signed 64-bit span per price, serialized as little-endian bytes. The return value is the number of span elements. The maximum output is 512 bytes.
- Invalid/null input returns `-1`. Input validation precedes output checks. A null output pointer or insufficient capacity returns `-2` without writing.
- Equal prices extend the span because both sources pop a previous price when `previous_price <= current_price`.

## Workload

[`workload.json`](workload.json) covers the published examples, increasing and decreasing streams, equal-price ties, multi-pop behavior, signed 32-bit boundaries, maximum length, malformed framing, null input/output, and output-capacity boundaries. See the [oracle](../../stock_span_problem_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/stock_span_problem.c`](../../../c/s/stock_span_problem.c) |
| C3 | [`c3/s/stock_span_problem.c3`](../../../c3/s/stock_span_problem.c3) |
| C++ | [`cpp/s/stock_span_problem.cpp`](../../../cpp/s/stock_span_problem.cpp) |
| Elisa | [`elisa/s/stock_span_problem.elisa`](../../../elisa/s/stock_span_problem.elisa) |
| Nim | [`nim/s/stock_span_problem.nim`](../../../nim/s/stock_span_problem.nim) |
| Odin | [`odin/s/stock_span_problem.odin`](../../../odin/s/stock_span_problem.odin) |
| Rust | [`rust/s/stock_span_problem.rs`](../../../rust/s/stock_span_problem.rs) |
| V | [`v/s/stock_span_problem.v`](../../../v/s/stock_span_problem.v) |
| Zig | [`zig/s/stock_span_problem.zig`](../../../zig/s/stock_span_problem.zig) |

## Pinned sources

- [TheAlgorithms/Java — `StockSpanProblem.calculateSpan`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/StockSpanProblem.java) at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
- [TheAlgorithms/Python — `calculate_span`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stock_span_problem.py) at `e1a2a8b016001309a73d5fec4818c35cca139795`.

The Python file's example driver prints output when run as a script; the benchmark calls the pure `calculate_span` routine and leaves that driver outside the measured function.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm stock_span_problem --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/stock_span_problem/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm stock_span_problem
```
