# Python travelling salesman Held–Karp dynamic programming

This package preserves `travelling_salesman_dynamic_programming` from the pinned Python graph module. Input is `[city_count, x0, y0, ...]`; positions represent insertion-ordered string keys in the source dictionary. The bounded domain uses 2–8 cities with integer coordinates in `[-16,16]`.

The method computes Euclidean distances, fills a subset-mask Held–Karp table, selects the first minimum final city in ascending index order, then reconstructs predecessors by scanning city indices in ascending order and matching the source's exact floating-point equality. Output is `[path_length, city_indices..., total_distance]`. This method has its own package because its table and tie-breaking path reconstruction differ from the separate brute-force function in the same file.

Malformed input returns `-1`; null output or insufficient capacity returns `-2` without writes. Distance comparisons use absolute and relative tolerance `1e-12`. See the [workload](workload.json), [oracle](../../travelling_salesman_python_held_karp_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/travelling_salesman_problem.py).
