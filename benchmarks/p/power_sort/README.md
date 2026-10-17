# PowerSort

Sort a bounded integer vector with the pinned Python PowerSort algorithm and return its values as little-endian signed 64-bit integers.

## Contract

- The `i64_array_bytes_output` ABI accepts `[reverse, n, values...]`, where `reverse` is `0` for ascending or `1` for descending, `n` is in `0..64`, and each value is in `[-1,000,000, 1,000,000]`. Valid input length is exactly `2 + n`; the parser accepts at most 67 values to detect trailing data.
- Preserve PowerSort's natural-run detection, descending-run reversal, node-power calculations, run-stack merge order, and stable merge rule (take the left value on equality). Reverse mode uses the source's numeric key negation, which is safe in the bounded value domain.
- On success, write the sorted values directly as `n` little-endian signed i64 values, without a length prefix, and return `8*n` bytes. The maximum output is 512 bytes. Empty input (`n=0`) succeeds with zero bytes, including a zero-capacity output buffer.
- Invalid input returns `-1`. A valid nonempty input with a null output pointer or capacity below `8*n` returns `-2` without writing output.

## Source semantics

The package follows [`power_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/power_sort.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The bounded contract uses integer values, so the source's reverse-key branch is numeric negation and the source's final reversal for nonnumeric keys does not apply.

See the [workload](workload.json) and [oracle](../../power_sort_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [power_sort.c](../../../c/p/power_sort.c) |
| C3 | [power_sort.c3](../../../c3/p/power_sort.c3) |
| C++ | [power_sort.cpp](../../../cpp/p/power_sort.cpp) |
| Elisa | [power_sort.elisa](../../../elisa/p/power_sort.elisa) |
| Nim | [power_sort.nim](../../../nim/p/power_sort.nim) |
| Odin | [power_sort.odin](../../../odin/p/power_sort.odin) |
| Rust | [power_sort.rs](../../../rust/p/power_sort.rs) |
| V | [power_sort.v](../../../v/p/power_sort.v) |
| Zig | [power_sort.zig](../../../zig/p/power_sort.zig) |
