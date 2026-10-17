# PCG32 random number generator

## Contract

Generate a bounded sequence of 32-bit values using the pinned Rust PCG32 implementation and its custom constructor. Input is a signed-i64 array encoded as [seed_bits, multiplier_bits, stream, count]. The seed and multiplier words are interpreted by their two's-complement bit patterns as u64 values. The stream must be in 0..2^63-1, matching the source documentation, and count must be in 0..256.

The source constructor computes increment = (stream << 1) | 1, initializes state with wrapping addition of the seed and increment, and advances once. Each get_u32 call reads the current state, advances with wrapping multiply/add, then applies the source xorshift and rotate-right output transform. The benchmark returns only the requested sequence; it does not expose the final state. The custom multiplier is accepted as any u64 bit pattern because the source constructor does not validate it.

The C ABI entry point is:

~~~c
int64_t pcg32_random(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity);
~~~

The input length must be exactly 4 words; a fifth parseable word is available to represent malformed trailing input. A null input, malformed length, stream outside its source domain, or count above 256 returns -1. Output is the generated values encoded as little-endian unsigned-i32 words, and success returns the number of bytes written. A null output pointer or insufficient capacity returns -2 after full input validation, and errors write no output. The maximum output is 1,024 bytes. A nonnull output pointer with zero capacity succeeds when count is zero.

## Workload

[workload.json](workload.json) covers the default PCG stream encoded through the custom constructor, alternate seed/multiplier/stream values, signed bit-pattern inputs, empty and maximum-length outputs, malformed parameters and lengths, null pointers, and output-capacity errors.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/random.c](../../../c/r/random.c) |
| C3 | [c3/r/random.c3](../../../c3/r/random.c3) |
| C++ | [cpp/r/random.cpp](../../../cpp/r/random.cpp) |
| Elisa | [elisa/r/random.elisa](../../../elisa/r/random.elisa) |
| Nim | [nim/r/random.nim](../../../nim/r/random.nim) |
| Odin | [odin/r/random.odin](../../../odin/r/random.odin) |
| Rust | [rust/r/random.rs](../../../rust/r/random.rs) |
| V | [v/r/random.v](../../../v/r/random.v) |
| Zig | [zig/r/random.zig](../../../zig/r/random.zig) |

## TheAlgorithms source

- [Rust random.rs at commit fed66cb0c74c4a939ec5163648458a8c2b46fd4c](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/random.rs)
