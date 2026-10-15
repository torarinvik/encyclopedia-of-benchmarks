# Count distinct elements in each window

This benchmark emits the number of distinct values in every complete contiguous window of a fixed size. It follows the pinned Java `CountDistinctElementsInWindow.countDistinct` implementation, which initializes a frequency map from the first window, then adds each entering value and removes each leaving value. The count is emitted after every slide, in left-to-right order.

## Contract

The `i64_array_bytes_output` ABI packs the input as signed 64-bit integers `[n, k, values...]`. The exact packed length is `n + 2`; `n` is 1..256, `k` is 1..n, and each value is a signed 32-bit integer. The output contains `n-k+1` signed 64-bit counts, each encoded in little-endian order, and success returns `8*(n-k+1)` bytes. Malformed packing, invalid bounds, or a value outside signed 32-bit range returns `-1`. Insufficient output capacity returns `-2`.

The pinned Java method throws for a null or empty array, `k <= 0`, or `k > n`. Those inputs are outside the valid benchmark domain and map to the shared `-1` invalid-input result. The benchmark bounds ensure all Java frequency counts remain safely within `int`.

## Source and distinction

Pinned source: [TheAlgorithms/Java `CountDistinctElementsInWindow.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/CountDistinctElementsInWindow.java).

This package returns a distinct-value count for every fixed-width window. It differs from `maximum_sum_of_distinct_subarrays_with_length_k`, which returns one maximum sum among windows whose values are all distinct, and from `max_sum_sliding_window`, which returns a maximum sum while allowing duplicates. It also differs from `windowed_median`, which emits a statistic over a trailing stream prefix.

`workload.json` covers duplicates, all-distinct windows, negative and boundary values, `k=1`, a full-array window, and invalid packed/domain inputs. The nine ports use the existing `i64_array_bytes_output` ABI family and a 512-slot open-addressed frequency table. A key remains occupied after its count reaches zero, so each entering and leaving value uses expected O(1) lookup without tombstones; the 512 slots cover all 256 possible distinct input values.
