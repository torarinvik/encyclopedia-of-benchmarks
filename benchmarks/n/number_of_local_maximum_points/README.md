# Number of local maximum points

Counts indices whose value is strictly greater than their neighboring values. An endpoint has only one neighbor to compare with.

## Contract

- Uses the `i64_array_scalar` ABI; the input is an array of signed integers and the ABI length is the array's element count.
- Valid arrays have length 1 through 4,096, and every value fits signed 32-bit range. Empty arrays, out-of-range values, and lengths above the bound return `-1`.
- Returns the number of local maximum points.
- The source's singleton behavior is preserved: a one-element array returns 0 because its first-element check compares against a missing next element.
- For length two, both endpoints are checked independently; because comparisons are strict, equal values produce 0 and unequal values produce 1.

## Source semantics

This follows pinned [TheAlgorithms JavaScript `NumberOfLocalMaximumPoints.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Array/NumberOfLocalMaximumPoints.js). The recursive traversal splits `[start, end]` at `floor((start + end) / 2)` and visits `[start, mid]` plus `[mid + 1, end]`. Each singleton index is tested once: index zero is greater than its next element; the final index is greater than its previous element; interior indices must be greater than both neighbors. Ties are not maxima.

The sibling `local_maximum_point` uses divide and conquer to return one peak index and accepts non-strict neighbor comparisons. It is a different operation from counting every strict local maximum. The bound limits the traversal to 4,096 values and keeps recursion depth logarithmic; the traversal visits every index once.

## Workload and build

[`workload.json`](workload.json) covers singleton behavior, two-element endpoint checks, strict ties, interior peaks, monotone arrays, and invalid inputs. Build and record with the array-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm number_of_local_maximum_points --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/number_of_local_maximum_points/rust/build.json
```

The nine implementations are in `c/n/number_of_local_maximum_points.c`, `c3/n/number_of_local_maximum_points.c3`, `cpp/n/number_of_local_maximum_points.cpp`, `elisa/n/number_of_local_maximum_points.elisa`, `nim/n/number_of_local_maximum_points.nim`, `odin/n/number_of_local_maximum_points.odin`, `rust/n/number_of_local_maximum_points.rs`, `v/n/number_of_local_maximum_points.v`, and `zig/n/number_of_local_maximum_points.zig`.
