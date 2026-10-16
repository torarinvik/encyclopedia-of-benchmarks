# Local binary pattern

The pinned Python routine compares eight neighbors with the center using >= and assigns weights 1,2,4,...,128 in this explicit order: top-right, right, top-middle, bottom-right, bottom-middle, bottom-left, left, top-left. This benchmark uses an interior center of a 3x3 grayscale patch, so every source neighbor lookup is in bounds.

## Contract

Input is nine row-major grayscale byte values. Output is the 8-bit weighted comparison pattern at the center. Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../local_binary_pattern_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/local_binary_pattern.py).

| Language | Port |
|---|---|
| C | [c/l/local_binary_pattern.c](../../../c/l/local_binary_pattern.c) |
| C3 | [c3/l/local_binary_pattern.c3](../../../c3/l/local_binary_pattern.c3) |
| C++ | [c++/l/local_binary_pattern.cpp](../../../c++/l/local_binary_pattern.cpp) |
| Elisa | [elisa/l/local_binary_pattern.elisa](../../../elisa/l/local_binary_pattern.elisa) |
| Nim | [nim/l/local_binary_pattern.nim](../../../nim/l/local_binary_pattern.nim) |
| Odin | [odin/l/local_binary_pattern.odin](../../../odin/l/local_binary_pattern.odin) |
| Rust | [rust/l/local_binary_pattern.rs](../../../rust/l/local_binary_pattern.rs) |
| V | [v/l/local_binary_pattern.v](../../../v/l/local_binary_pattern.v) |
| Zig | [zig/l/local_binary_pattern.zig](../../../zig/l/local_binary_pattern.zig) |
