# Count Homogenous Runs

Count the number of contiguous runs of equal bytes in a string.

## Source

This package preserves the behavior of the pinned [TheAlgorithms/PHP `countHomogenous`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/CountHomogenous.php) function. Although the name and comment mention homogeneous substrings, the implementation increments its result only when adjacent bytes differ, so it returns the number of maximal equal-byte runs. An empty string returns zero.

## Contract

- ABI: `i64_array_scalar`, with packed input `[byte_count, ASCII byte values...]`.
- `byte_count` is in `0..=4096`, the array contains exactly `byte_count + 1` values, and each byte value is in `0..=127`.
- Return `0` for an empty input; otherwise return one plus the number of adjacent byte changes. Invalid count, length, or byte values return `-1`.
- The input is read only. The result is between 0 and 4096.

## Workload and ports

[`workload.json`](workload.json) covers empty, single-byte, repeated, alternating, mixed-run, ASCII-boundary, maximum-length, and malformed inputs. The independent oracle is [`count_homogenous_oracle.py`](../../count_homogenous_oracle.py). Nine ports export `count_homogenous` for the shared `i64_array_scalar` runner.

Verify the nine ports against the independent oracle with `python3 benchmarks/verify_i64_array_scalar.py --algorithms count_homogenous`.
