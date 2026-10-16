# Magic Diamond Pattern

The pinned Python source exposes `floyd`, `reverse_floyd`, and `pretty_print`. The benchmark covers the combined text returned by `pretty_print(n)`. For positive `n`, it emits the upper Floyd triangle followed by the reverse Floyd triangle, preserving every space, `* ` pair, newline, and trailing spaces exactly. For `n <= 0`, it returns the source sentinel `"       ...       ....        nothing printing :("`.

The scalar-to-bytes ABI accepts signed 64-bit `n`; values above 45 return `-1`. A null output buffer or a capacity smaller than the required result returns `-2`. Positive-side output is at most 6,255 bytes. The workload checks sentinel behavior, small patterns, maximum size, invalid range, and insufficient capacity.

All nine implementations are provided:

- [C](../../../c/m/magicdiamondpattern.c)
- [C3](../../../c3/m/magicdiamondpattern.c3)
- [C++](../../../cpp/m/magicdiamondpattern.cpp)
- [Elisa](../../../elisa/m/magicdiamondpattern.elisa)
- [Nim](../../../nim/m/magicdiamondpattern.nim)
- [Odin](../../../odin/m/magicdiamondpattern.odin)
- [Rust](../../../rust/m/magicdiamondpattern.rs)
- [V](../../../v/m/magicdiamondpattern.v)
- [Zig](../../../zig/m/magicdiamondpattern.zig)

Pinned source: [TheAlgorithms/Python `other/magicdiamondpattern.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/magicdiamondpattern.py).
