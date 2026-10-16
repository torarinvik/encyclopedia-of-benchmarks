# Majority element by sorting

The pinned Dart routine called `Moore_voting_algorithm.dart` sorts its input and counts equal runs; it does not use Moore voting. It returns the repeated value only when its frequency is strictly greater than half the input size, otherwise `-1`.

## Contract

Input is 2 through 128 signed 32-bit integers represented as i64 values. The routine sorts a private copy, scans consecutive equal values, and returns the strict majority value or `-1`. The minimum length of two preserves the source's behavior domain while avoiding its empty and singleton indexing/loop edge cases. The benchmark uses insertion sort so the named sort-and-count strategy remains explicit.

See [`workload.json`](workload.json) and the runtime [oracle](../../majority_element_sort_oracle.py).

Pinned source: [TheAlgorithms/Dart `Moore_voting_algorithm.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/Moore_voting_algorithm.dart).

| Language | Port |
|---|---|
| C | [`c/m/majority_element_sort.c`](../../../c/m/majority_element_sort.c) |
| C3 | [`c3/m/majority_element_sort.c3`](../../../c3/m/majority_element_sort.c3) |
| C++ | [`cpp/m/majority_element_sort.cpp`](../../../cpp/m/majority_element_sort.cpp) |
| Elisa | [`elisa/m/majority_element_sort.elisa`](../../../elisa/m/majority_element_sort.elisa) |
| Nim | [`nim/m/majority_element_sort.nim`](../../../nim/m/majority_element_sort.nim) |
| Odin | [`odin/m/majority_element_sort.odin`](../../../odin/m/majority_element_sort.odin) |
| Rust | [`rust/m/majority_element_sort.rs`](../../../rust/m/majority_element_sort.rs) |
| V | [`v/m/majority_element_sort.v`](../../../v/m/majority_element_sort.v) |
| Zig | [`zig/m/majority_element_sort.zig`](../../../zig/m/majority_element_sort.zig) |
