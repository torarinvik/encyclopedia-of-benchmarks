# Mirror

This benchmark ports the pinned C `miroir(char *s)` routine. It reverses the bytes before the first NUL in a writable buffer and returns the same buffer pointer. The algorithm counts the bytes, then swaps the first and last, moving inward; an empty string remains empty. The interactive `main` and its unbounded token read are outside this benchmark.

## Contract

Input is a signed 64-bit integer array `[byte_length, ASCII bytes...]`. `byte_length` is 0 through 256, the array length is exactly `byte_length + 1`, and each byte is in 1 through 127. ASCII whitespace is accepted because the benchmark calls the function directly rather than using the demo's token reader. NUL is excluded because it terminates the source string.

Each adapter validates the packed input, copies its bytes into a bounded writable NUL-terminated local buffer, counts up to that terminator, reverses the buffer in place, and serializes the mutated bytes to the ABI output buffer. This preserves the source's in-place byte semantics; the adapter translates the source's same-buffer pointer return into the output length before the terminating NUL. Malformed input returns `-1`; a null or undersized output buffer returns `-2` without writing. Maximum output capacity is 257 bytes.

The independent [oracle](../../mirror_oracle.py) and [`workload.json`](workload.json) cover empty, even and odd, whitespace/control-byte, maximum-length, malformed, null-pointer, and output-capacity cases.

## Pinned source

- [TheAlgorithms/C `misc/mirror.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/mirror.c)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/mirror.c`](../../../c/m/mirror.c) |
| C3 | [`c3/m/mirror.c3`](../../../c3/m/mirror.c3) |
| C++ | [`cpp/m/mirror.cpp`](../../../cpp/m/mirror.cpp) |
| Elisa | [`elisa/m/mirror.elisa`](../../../elisa/m/mirror.elisa) |
| Nim | [`nim/m/mirror.nim`](../../../nim/m/mirror.nim) |
| Odin | [`odin/m/mirror.odin`](../../../odin/m/mirror.odin) |
| Rust | [`rust/m/mirror.rs`](../../../rust/m/mirror.rs) |
| V | [`v/m/mirror.v`](../../../v/m/mirror.v) |
| Zig | [`zig/m/mirror.zig`](../../../zig/m/mirror.zig) |

The adapters use the `i64_array_bytes_output` ABI.
