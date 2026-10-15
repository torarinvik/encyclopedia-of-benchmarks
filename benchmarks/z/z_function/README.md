# Z-function

Compute the Z-array for an input string. Entry `z[i]` is the longest prefix length that matches the substring beginning at `i`; `z[0]` is zero, matching both pinned implementations.

## Contract

The `i64_array_bytes_output` input is an array of ASCII code points in `[0,127]`, with length from 0 through 256. The result is the Z-array, encoded as one signed 64-bit little-endian integer per input position; a valid call returns `8 * length`. Invalid length or code points return `-1`. Insufficient output capacity, or a null output pointer when bytes are required, returns `-2`.

Restricting the string to ASCII gives the C++ byte-string and Python Unicode-string sources the same character comparisons. The related `z_algorithm` benchmark searches for a pattern; this package returns the Z-array itself.

The shared `run_i64_array_bytes_output.py` runner checks the source-matched Z-values and their little-endian output encoding before timing.

## Workload

[`workload.json`](workload.json) covers empty and singleton strings, repeated and alternating characters, the pinned `abracadabra` example, embedded NUL, invalid input, and insufficient capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/z/z_function.c`](../../../c/z/z_function.c) |
| C3 | [`c3/z/z_function.c3`](../../../c3/z/z_function.c3) |
| C++ | [`cpp/z/z_function.cpp`](../../../cpp/z/z_function.cpp) |
| Elisa | [`elisa/z/z_function.elisa`](../../../elisa/z/z_function.elisa) |
| Nim | [`nim/z/z_function.nim`](../../../nim/z/z_function.nim) |
| Odin | [`odin/z/z_function.odin`](../../../odin/z/z_function.odin) |
| Rust | [`rust/z/z_function.rs`](../../../rust/z/z_function.rs) |
| V | [`v/z/z_function.v`](../../../v/z/z_function.v) |
| Zig | [`zig/z/z_function.zig`](../../../zig/z/z_function.zig) |

## Pinned sources

- C++ [`z_function.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/z_function.cpp)
- C++-1 [`z_function.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/z_function.cpp)
- Python [`z_function.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/z_function.py)
