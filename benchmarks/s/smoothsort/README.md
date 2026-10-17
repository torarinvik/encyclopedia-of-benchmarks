# Smoothsort

This package exposes the sorted result of the pinned Python
[`smoothsort`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/smoothsort.py)
implementation. The source builds a forest of Leonardo heaps, extracts their
maximum roots from right to left, mutates the input list in place, and returns
that same list in ascending order.

## Contract

The `i64_array_bytes_output` input is `[count, value_0, ..., value_(count-1)]`.
`count` is 0–64, and the input has exactly `1 + count` signed 64-bit integers.
The full signed 64-bit value range is supported. The maximum valid input has
65 words; 66 are parseable so trailing data can be rejected.

The source compares values using `<`; with this integer wrapper that is signed
numeric order. Output is the input values in ascending order, including all
duplicates, encoded as little-endian signed 64-bit integers. The ABI exposes
the source's sorted in-place result as a separate output vector; list identity
is not observable across the wrapper. An empty input list is valid and returns
an empty vector.

Malformed input or a count/shape violation returns `-1` before output checks.
The return value and output capacity are measured in bytes. A null output
pointer returns `-2`, including for an empty result. A nonnull capacity-zero
buffer succeeds when the required output is empty; a smaller-than-required
capacity returns `-2`. Errors write nothing. The maximum output is 64 values,
or 512 bytes.

The independent sorted-list oracle is
[`benchmarks/smoothsort_oracle.py`](../../smoothsort_oracle.py), and fixtures
are in [`workload.json`](workload.json). This package remains distinct from
[`smooth_sort`](../smooth_sort/README.md); the candidate review requires
separate source coverage unless exact in-place ABI parity is established.

## Source

The source is pinned to TheAlgorithms/Python commit
`e1a2a8b016001309a73d5fec4818c35cca139795`, path `sorts/smoothsort.py`, symbol
`smoothsort`.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/smoothsort.c`](../../../c/s/smoothsort.c) |
| C3 | [`c3/s/smoothsort.c3`](../../../c3/s/smoothsort.c3) |
| C++ | [`cpp/s/smoothsort.cpp`](../../../cpp/s/smoothsort.cpp) |
| Elisa | [`elisa/s/smoothsort.elisa`](../../../elisa/s/smoothsort.elisa) |
| Nim | [`nim/s/smoothsort.nim`](../../../nim/s/smoothsort.nim) |
| Odin | [`odin/s/smoothsort.odin`](../../../odin/s/smoothsort.odin) |
| Rust | [`rust/s/smoothsort.rs`](../../../rust/s/smoothsort.rs) |
| V | [`v/s/smoothsort.v`](../../../v/s/smoothsort.v) |
| Zig | [`zig/s/smoothsort.zig`](../../../zig/s/smoothsort.zig) |

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm smoothsort --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm smoothsort
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm smoothsort --languages rust
~~~
