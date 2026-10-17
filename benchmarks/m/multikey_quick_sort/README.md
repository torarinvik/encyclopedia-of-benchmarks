# Multikey quicksort

This benchmark ports the deterministic `ssort2main` entry point from the pinned C source. The source also has `ssort1main`, a randomized variant that the upstream demo's `main` calls; this benchmark deliberately measures `ssort2main` and does not reproduce the demo path.

## Contract

- The ABI is `i32_array_bytes_output`. Input is a signed-i32 word array `[count, (length, ASCII byte...) ...]`. The count is 0–32, each string length is 0–16, and the total input has exactly `1 + sum(1 + length)` words. Bytes must be 1–127: NUL is reserved for the source's C string terminator, and values above 127 are outside the ASCII domain. Empty strings and duplicates are valid.
- `ssort2main` sorts strings in ascending bytewise lexicographic order. A shorter string precedes a longer string with the same prefix. The selected path is deterministic: it uses insertion sort below 10 items, median-of-three pivot selection, and a pseudomedian-of-nine for more than 30 items. Its three-way partition recurses on the equal-character group at the next string depth and on lower/higher groups at the current depth. The benchmark preserves the sorted byte strings and does not depend on quicksort's internal arrangement of equal values.
- Output is `[count, (length, ASCII byte...) ...]` in the same little-endian signed-i32 byte format. The empty list encodes as `[0]` (4 bytes). At the input bounds, the largest valid input and output are 545 words and 2,180 bytes. Malformed or out-of-domain input returns `-1` before output-buffer checks. A null output or insufficient output capacity returns `-2` without writes.

The workload covers empty and singleton lists, empty and duplicate strings, prefix ordering, ASCII byte boundaries, insertion-sort and quicksort paths, the pseudomedian-of-nine path, maximum input/output, malformed framing, domain errors, and output capacity. See [workload.json](workload.json) and the independent [oracle](../../multikey_quick_sort_oracle.py).

Pinned source: [TheAlgorithms/C `multikey_quick_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/multikey_quick_sort.c) at commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm multikey_quick_sort --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/multikey_quick_sort/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithms multikey_quick_sort --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/multikey_quick_sort.c](../../../c/m/multikey_quick_sort.c) |
| C3 | [c3/m/multikey_quick_sort.c3](../../../c3/m/multikey_quick_sort.c3) |
| C++ | [cpp/m/multikey_quick_sort.cpp](../../../cpp/m/multikey_quick_sort.cpp) |
| Elisa | [elisa/m/multikey_quick_sort.elisa](../../../elisa/m/multikey_quick_sort.elisa) |
| Nim | [nim/m/multikey_quick_sort.nim](../../../nim/m/multikey_quick_sort.nim) |
| Odin | [odin/m/multikey_quick_sort.odin](../../../odin/m/multikey_quick_sort.odin) |
| Rust | [rust/m/multikey_quick_sort.rs](../../../rust/m/multikey_quick_sort.rs) |
| V | [v/m/multikey_quick_sort.v](../../../v/m/multikey_quick_sort.v) |
| Zig | [zig/m/multikey_quick_sort.zig](../../../zig/m/multikey_quick_sort.zig) |
