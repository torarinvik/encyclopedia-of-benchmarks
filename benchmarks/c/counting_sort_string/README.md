# Counting Sort String

Sort the characters in a token by ascending ASCII byte value using a 256-entry counting array. This follows the pinned [TheAlgorithms/C-Plus-Plus source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/counting_sort_string.cpp), which counts byte values, forms cumulative counts, and writes the sorted characters. The second cataloged C++ repository has the same source at its pinned revision.

## Contract

- Input is `[n, byte_0, ..., byte_(n-1)]`, with `n` from 0 through 4,095.
- Each byte must be printable non-space ASCII, 33 through 126. This matches the source demo's whitespace-delimited token input and avoids its NUL terminator and signed-char indexing hazards.
- Return the number of output bytes and emit the input characters sorted in ascending byte order. Empty input returns zero bytes.
- Invalid input returns `-1`; null or insufficient output storage returns `-2` without writing.

The pinned C++ source declares an empty output string and indexes into it before growing it, which is undefined behavior. The ports allocate the bounded output storage first and preserve the source's counting and cumulative-position algorithm. The implementation uses portable integer and array operations, with O(n + 256) time and O(256) auxiliary counters.

## Implementations

| Language | Implementation |
| --- | --- |
| C | [`c/c/counting_sort_string.c`](../../../c/c/counting_sort_string.c) |
| C3 | [`c3/c/counting_sort_string.c3`](../../../c3/c/counting_sort_string.c3) |
| C++ | [`cpp/c/counting_sort_string.cpp`](../../../cpp/c/counting_sort_string.cpp) |
| Elisa | [`elisa/c/counting_sort_string.elisa`](../../../elisa/c/counting_sort_string.elisa) |
| Nim | [`nim/c/counting_sort_string.nim`](../../../nim/c/counting_sort_string.nim) |
| Odin | [`odin/c/counting_sort_string.odin`](../../../odin/c/counting_sort_string.odin) |
| Rust | [`rust/c/counting_sort_string.rs`](../../../rust/c/counting_sort_string.rs) |
| V | [`v/c/counting_sort_string.v`](../../../v/c/counting_sort_string.v) |
| Zig | [`zig/c/counting_sort_string.zig`](../../../zig/c/counting_sort_string.zig) |

The shared cases are in [`workload.json`](workload.json). Build an implementation and its ABI checker with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm counting_sort_string --language <language> --with-checker`.
