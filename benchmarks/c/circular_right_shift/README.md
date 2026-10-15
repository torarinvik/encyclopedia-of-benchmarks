# Circular right shift (uint53)

The pinned Lua implementation rotates a nonnegative 53-bit integer right by a shift from 0 through 53. It takes the low `shift` bits with `n % 2^shift`, moves them to the high end with multiplication by `2^(53-shift)`, and adds `floor(n / 2^shift)`.

## Contract

- The binary scalar input pair is `[n, shift]`, with both values passed as unsigned 64-bit words.
- `n` is in `0..=2^53-1`; `shift` is in `0..=53`.
- Return the 53-bit circular right rotation as a nonnegative signed 64-bit result.
- Return `-1` when either input is outside its supported range.

The Lua number operations are exact on this domain. Inputs and powers of two are exactly representable in binary64; scaling by powers of two changes only the exponent, and dividing by a power of two retains enough binary precision for the exact floor. Modulo `2^shift` selects the low bits. The ports express the same operation with integer bit slices: move the low `shift` bits to the high end and retain the remaining high bits in place.

This is the rightward direction of the Lua 53-bit `uint53` operation. [`circular_left_shift`](../circular_left_shift/README.md) is the separate leftward operation. Both use a 53-bit word; the Java `BitRotate` and Python `rotate_bits` APIs instead rotate 32-bit words.

The ABI is `int64_t circular_right_shift(uint64_t n, uint64_t shift)` and uses the existing `binary_scalar` family.

## Workload

[`workload.json`](workload.json) covers both shift endpoints, zero, wraparound of low bits, the maximum uint53 value, and out-of-domain words.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/circular_right_shift.c`](../../../c/c/circular_right_shift.c) |
| C3 | [`c3/c/circular_right_shift.c3`](../../../c3/c/circular_right_shift.c3) |
| C++ | [`cpp/c/circular_right_shift.cpp`](../../../cpp/c/circular_right_shift.cpp) |
| Elisa | [`elisa/c/circular_right_shift.elisa`](../../../elisa/c/circular_right_shift.elisa) |
| Nim | [`nim/c/circular_right_shift.nim`](../../../nim/c/circular_right_shift.nim) |
| Odin | [`odin/c/circular_right_shift.odin`](../../../odin/c/circular_right_shift.odin) |
| Rust | [`rust/c/circular_right_shift.rs`](../../../rust/c/circular_right_shift.rs) |
| V | [`v/c/circular_right_shift.v`](../../../v/c/circular_right_shift.v) |
| Zig | [`zig/c/circular_right_shift.zig`](../../../zig/c/circular_right_shift.zig) |

## Upstream source

- [TheAlgorithms/Lua `circular_right_shift.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/circular_right_shift.lua)
- [TheAlgorithms/Java `BitRotate.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BitRotate.java) and [TheAlgorithms/Python `rotate_bits.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/rotate_bits.py) are separate 32-bit APIs.
