# Lower bound

## Contract

This benchmark ports the Java `lower_bound` routine from [TheAlgorithms/Java, `searches/LowerBound.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/searches/LowerBound.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

The source recursively searches inclusive bounds `[left, right]`, initially `[0, n - 1]`. It computes the midpoint as `(left + right) / 2`; an equal value returns that midpoint immediately, a smaller target recurses into `[left, middle]`, and a larger target recurses into `[middle + 1, right]`. Once `right <= left`, it returns `left`.

Those details produce source-specific edge behavior: an empty input returns 0; a target above the maximum returns `n - 1`; duplicate hits return whichever equal midpoint the recursion encounters first. This is not the conventional insertion-point lower bound. The PHP sibling returns an insertion position and returns `n` above the maximum; standard binary search also has a different miss contract.

The portable benchmark domain is an array of 0..512 signed int32 values in nondecreasing order and a signed int32 target. It returns the source result as an index. Invalid length, value, target, null nonempty input, or descending adjacent pair returns -1. This bounded contract keeps all midpoint arithmetic safe while preserving the pinned recursion.

Each language exports the shared search ABI:

```c
int64_t lower_bound(const int64_t *values, size_t length, int64_t target);
```

The workload uses strictly increasing generated arrays, so duplicate midpoint behavior is documented from source but is not exercised by generated cases.

## Workload

`workload.json` generates arrays with `values[index] = 2 * index - length` at lengths 1, 16, 128, and 512. It measures first, middle, and last hits, plus values below and above the generated range. The source returns 0 for a below-minimum miss and the last index for an above-maximum miss.

## Implementations

The nine local ports preserve the recursive inclusive-bound source behavior and apply the same validation contract at the ABI boundary.
