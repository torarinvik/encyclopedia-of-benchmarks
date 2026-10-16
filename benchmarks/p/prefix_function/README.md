# Prefix function

The pinned F# and Python sources compute the KMP prefix function: for each position, the output is the length of the longest proper prefix of the prefix ending there that is also a suffix. Both use the linear fallback recurrence through prior prefix values. The F# comments explicitly distinguish this from KMP pattern search.

## Contract

Input is `[text_length, ASCII_bytes...]`, with length 0 through 4096 and bytes 0 through 127. Output is one little-endian signed i32 prefix value per input byte, in position order. The call returns `4 * text_length` bytes; malformed input returns `-1`; insufficient capacity returns `-2`. Empty text returns zero bytes.

Pinned sources: [F#](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/PrefixFunction.fs) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/prefix_function.py). [`workload.json`](workload.json) exercises empty, repeated, fallback-heavy, invalid, and capacity-limited inputs. Runtime oracle: [`benchmarks/prefix_function_oracle.py`](../../prefix_function_oracle.py).

| Language | Port |
|---|---|
| C | [`c/p/prefix_function.c`](../../../c/p/prefix_function.c) |
| C3 | [`c3/p/prefix_function.c3`](../../../c3/p/prefix_function.c3) |
| C++ | [`cpp/p/prefix_function.cpp`](../../../cpp/p/prefix_function.cpp) |
| Elisa | [`elisa/p/prefix_function.elisa`](../../../elisa/p/prefix_function.elisa) |
| Nim | [`nim/p/prefix_function.nim`](../../../nim/p/prefix_function.nim) |
| Odin | [`odin/p/prefix_function.odin`](../../../odin/p/prefix_function.odin) |
| Rust | [`rust/p/prefix_function.rs`](../../../rust/p/prefix_function.rs) |
| V | [`v/p/prefix_function.v`](../../../v/p/prefix_function.v) |
| Zig | [`zig/p/prefix_function.zig`](../../../zig/p/prefix_function.zig) |
