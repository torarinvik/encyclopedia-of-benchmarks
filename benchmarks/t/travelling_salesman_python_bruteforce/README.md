# Python travelling salesman brute force

This package preserves `travelling_salesman_brute_force` from the pinned Python graph module. Input is `[city_count, x0, y0, ...]`; the positions represent insertion-ordered string keys in the source dictionary. The bounded domain uses 2–8 cities with integer coordinates in `[-16,16]`.

The first city is the start. The method enumerates permutations of the remaining cities in insertion order, sums Euclidean edge distances from left to right, and keeps the first route whose distance is a strict new minimum. Output is `[path_length, city_indices..., total_distance]`; indices encode the source dictionary keys by insertion order. This package covers the exhaustive permutation method only; the Held–Karp method has a separate contract because its reconstruction and tie behavior differ.

Malformed input returns `-1`; null output or insufficient capacity returns `-2` without writes. Distance comparisons use absolute and relative tolerance `1e-12`. See the [workload](workload.json), [oracle](../../travelling_salesman_python_bruteforce_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/travelling_salesman_problem.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/t/travelling_salesman_python_bruteforce.c`](../../../c/t/travelling_salesman_python_bruteforce.c) |
| C3 | [`c3/t/travelling_salesman_python_bruteforce.c3`](../../../c3/t/travelling_salesman_python_bruteforce.c3) |
| C++ | [`cpp/t/travelling_salesman_python_bruteforce.cpp`](../../../cpp/t/travelling_salesman_python_bruteforce.cpp) |
| Elisa | [`elisa/t/travelling_salesman_python_bruteforce.elisa`](../../../elisa/t/travelling_salesman_python_bruteforce.elisa) |
| Nim | [`nim/t/travelling_salesman_python_bruteforce.nim`](../../../nim/t/travelling_salesman_python_bruteforce.nim) |
| Odin | [`odin/t/travelling_salesman_python_bruteforce.odin`](../../../odin/t/travelling_salesman_python_bruteforce.odin) |
| Rust | [`rust/t/travelling_salesman_python_bruteforce.rs`](../../../rust/t/travelling_salesman_python_bruteforce.rs) |
| V | [`v/t/travelling_salesman_python_bruteforce.v`](../../../v/t/travelling_salesman_python_bruteforce.v) |
| Zig | [`zig/t/travelling_salesman_python_bruteforce.zig`](../../../zig/t/travelling_salesman_python_bruteforce.zig) |
