# Smallest Divisor

This benchmark implements the C LeetCode 1283 search from TheAlgorithms/C. It finds the least positive divisor for which the sum of each positive input value rounded up after division is no greater than the threshold.

The packed input starts with the threshold followed by 1 to 256 values in 1..1,000,000. The threshold is in 1..1,000,000. Invalid inputs and thresholds below the number of values return -1.

The ports bound the binary search using the total and the number of values. For total `S`, count `n`, and divisor `d`, the rounded sum lies between `S/d` and `n + floor((S - n)/d)`. Short arrays use direct division. For longer arrays the loop computes `ceil(2^40/d)` once per divisor and obtains each quotient by multiplying and shifting. The reciprocal error is smaller than the distance to the next quotient because `(value - 1) * d < 2^40`. The products fit in 64 bits.

The verifier exhausts short arrays over values 1 through 5 and small thresholds, adds deterministic random inputs and value/length boundaries, and compares results to a direct scan of every divisor. The pinned source is [TheAlgorithms/C LeetCode 1283](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1283.c). Run the verifier with the Elisa compiler path supplied. Include Mojo by passing `--languages mojo`.
