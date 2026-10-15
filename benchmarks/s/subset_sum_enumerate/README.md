# Subset Sum Enumeration

Enumerate all indexed subsets whose values add to a target. Duplicate values at different positions produce distinct subsets.

## Contract

- The input is `[target, item0, ...]`; a target with no items is valid.
- There may be at most 8 items. The target must be in `[-512, 512]`; each item must be in `[-64, 64]`.
- Return the number of matching subsets and write one byte per subset: the subset's index mask, with bit `i` set when item `i` is included. Masks are emitted in ascending numeric order. For target zero, the empty subset is included.
- Invalid input returns `-1`. Insufficient output capacity returns `-2` without writing output.

## Reviewed TheAlgorithms source

The R [`subset_sum.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/subset_sum.r) file also contains `find_all_subsets`. Its recursive enumerator uses a positive-value pruning rule and emits subsets as value vectors. This benchmark defines a portable bounded contract over signed values and identifies subsets by input position so duplicate values remain distinguishable.

## Workload and verification

[`workload.json`](workload.json) covers the empty subset, duplicate values, signed values, and invalid inputs. [`benchmarks/verify_subset_sum_enumerate.py`](../../verify_subset_sum_enumerate.py) checks all nine ports against exhaustive subset masks and verifies output-capacity handling.

## Implementations

All nine implementations use the shared i64-array/bytes-output ABI.
