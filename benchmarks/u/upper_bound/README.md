# Upper bound

## Contract

This benchmark ports TheAlgorithms/Java's `UpperBound.find` implementation from [the pinned `UpperBound.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/UpperBound.java) and compares it with the pinned [PHP `UpperBound.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Searches/UpperBound.php).

The Java source recursively searches inclusive bounds `[left, right]`, initially `[0, n - 1]`. If `right <= left`, it returns `left` without inspecting that final element. Otherwise it computes the midpoint, recurses left only when `target < values[middle]`, and recurses right for equal or larger values. On a nonempty sorted array, this returns the first index whose value is greater than the target, except that an insertion point at `n` is returned as `n - 1`. Empty input returns 0. Thus an exact match among duplicates advances past the equal run when a later element exists; a match at or above the maximum returns the final index.

The Java class comment describes the first element greater than the target, but the code's inclusive base case clamps the end position to `n - 1`. The PHP sibling uses the conventional half-open binary search (`lo=0`, `hi=count(array)`) and returns the insertion point in `0..n`, including `n` when every value is at most the target. This is a distinct boundary search from the existing Java-canonical `lower_bound`, whose equality branch returns the encountered midpoint immediately.

The portable input is 0..512 signed int32 values in nondecreasing order and a signed int32 target. The result is the Java source index behavior above. Invalid length, out-of-domain value/target, or descending adjacent pair returns -1. Inputs are passed through the shared search ABI:

```c
int64_t upper_bound(const int64_t *values, size_t length, int64_t target);
```

## Workload

The workload uses lengths 2, 16, 128, and 512. Each generated array contains duplicates: every value is `-length`. It measures targets equal to that repeated value, below it, and above it. Equal and above-maximum searches return the last index under the Java implementation; the below-minimum search returns 0. This exposes the Java/PHP end-boundary difference.

## Implementations

The nine local ports preserve the Java inclusive recursion and its final-index clamp.
