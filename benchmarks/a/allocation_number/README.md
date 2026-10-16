# Allocation number

This benchmark partitions a byte range into contiguous, non-overlapping ranges for workers.

## Contract

- The input array is `[number_of_bytes, partitions]`, with exactly two signed 64-bit values.
- `number_of_bytes` is in `1..=1,000,000`; `partitions` is in `1..=128` and cannot exceed `number_of_bytes`.
- Each earlier partition receives `floor(number_of_bytes / partitions)` bytes. The final partition receives the remainder, matching the pinned Python source.
- The source returns a list of strings such as `['1-3', '4-6', '7-10']`. The C ABI serializes the same sequence as comma-separated ASCII, without brackets, quotes, or spaces, and returns the output byte length.
- Invalid input shape or values return `-1`; insufficient output capacity returns `-2`.

The input bounds keep output small and fit the shared `i64_array_bytes_output` runner. The range labels are one-based and inclusive, as in the source examples.

## Inspected upstream source

- [Python — `allocation_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/allocation_number.py)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`. Implementations are in `a/` in all nine language directories.

Verify all nine ports against the independent partition oracle with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm allocation_number
```
