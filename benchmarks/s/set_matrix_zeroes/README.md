# Set matrix zeroes

This package ports the pinned in-place matrix transformation. If any entry is zero, its entire row and column become zero.

## Contract

Input is `[rows, columns, row_major_cells...]`, with dimensions from 1 through 8, exactly `2 + rows*columns` values, and each cell in [-1,000,000, 1,000,000]. The input may contain one additional value for malformed-input coverage. The output is the transformed matrix as row-major signed 64-bit little-endian values, with no dimension prefix. A successful call returns the output byte count; invalid input returns -1; a null output or insufficient capacity returns -2 without writing. Maximum output size is 512 bytes.

The port follows the source's first-row and first-column marker algorithm, including its separate marker for whether the first column must be cleared. See [workload](workload.json) and [oracle](../../set_matrix_zeroes_oracle.py).

Pinned source: [set_matrix_zeroes.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/set_matrix_zeroes.py).

| Language | Port |
|---|---|
| C | ../../../c/s/set_matrix_zeroes.c |
| C3 | ../../../c3/s/set_matrix_zeroes.c3 |
| C++ | ../../../cpp/s/set_matrix_zeroes.cpp |
| Elisa | ../../../elisa/s/set_matrix_zeroes.elisa |
| Nim | ../../../nim/s/set_matrix_zeroes.nim |
| Odin | ../../../odin/s/set_matrix_zeroes.odin |
| Rust | ../../../rust/s/set_matrix_zeroes.rs |
| V | ../../../v/s/set_matrix_zeroes.v |
| Zig | ../../../zig/s/set_matrix_zeroes.zig |
