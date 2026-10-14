# Merge-insertion sort

The benchmark pairs adjacent values, orders the two values in each pair, and merge-sorts the pairs by their lower values. It starts a sorted chain from those lower values, then binary-inserts the remaining upper values and any unpaired final value. The nine ports sort signed 64-bit values in place up to length 256. Pair ordering takes `O(n log n)` time; array insertion moves values, so total worst-case time is `O(n^2)` with `O(n)` scratch storage.

The pinned Python source implements pair ordering followed by binary insertion. The two C++ copies describe a merge/insertion hybrid, but their test invokes only plain insertion sort and leaves the hybrid call commented out. The shared contract follows the Python pair-and-insert method and uses full-chain lower-bound insertion for a simpler, explicit duplicate rule.

Run `python3 benchmarks/verify_merge_insertion_sort.py` to check short-array order and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream references

- [Python `merge_insertion_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/merge_insertion_sort.py)
- [C++ `merge_insertion_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/merge_insertion_sort.cpp)
- [Additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/merge_insertion_sort.cpp)
