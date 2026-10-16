# Go Heap permutation order

## Contract

This package preserves the pinned Go `Heaps` source's output order. Input is `[n]`, where `n` is from 0 through 7. The source generates the distinct single-byte labels `'1'` through `'n'` and joins each permutation into an `n`-character string. The ABI serializes those fixed-width strings by concatenating their ASCII bytes with no separators or NUL terminators.

For `n=3`, the emitted rows are `123`, `213`, `321`, `231`, `312`, `132`. This is distinct from the pinned Dart/Python `heaps_algorithm` order (`123`, `213`, `312`, `132`, `231`, `321`) and from the Rust `heap_permutation` swap-before-recursion order. The Go source accepts no duplicate-value input and its generated labels are unique. For `n=0`, it emits no rows and returns 0 with empty output.

The successful result is the number of emitted rows (`n!` for `n>=1`, and 0 for `n=0`). Invalid input returns `-1`; insufficient output capacity returns `-2` and writes no output. Input length 2 is the parser limit and is rejected as overlength. The maximum output is `7! * 7 = 35,280` bytes.

## Workload

Cases and expected bytes are in [`workload.json`](workload.json). The package uses the `i64_array_bytes_output` ABI.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/heaps.c`](../../../c/h/heaps.c) |
| C3 | [`c3/h/heaps.c3`](../../../c3/h/heaps.c3) |
| C++ | [`cpp/h/heaps.cpp`](../../../cpp/h/heaps.cpp) |
| Elisa | [`elisa/h/heaps.elisa`](../../../elisa/h/heaps.elisa) |
| Nim | [`nim/h/heaps.nim`](../../../nim/h/heaps.nim) |
| Odin | [`odin/h/heaps.odin`](../../../odin/h/heaps.odin) |
| Rust | [`rust/h/heaps.rs`](../../../rust/h/heaps.rs) |
| V | [`v/h/heaps.v`](../../../v/h/heaps.v) |
| Zig | [`zig/h/heaps.zig`](../../../zig/h/heaps.zig) |

## TheAlgorithms reference

- [Go `heaps.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/permutation/heaps.go)
