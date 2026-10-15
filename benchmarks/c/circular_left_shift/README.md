# Circular left shift (uint53)

The pinned Lua implementation rotates a nonnegative 53-bit integer left by a shift from 0 through 53. It computes the high bits with `floor(n / 2^(53-shift))` and adds them to `(n * 2^shift) % 2^53`.

## Contract

- The binary scalar input pair is `[n, shift]`, with both values passed as unsigned 64-bit words.
- `n` is in `0..=2^53-1`; `shift` is in `0..=53`.
- Return the 53-bit circular left rotation as a nonnegative signed 64-bit result.
- Return `-1` when either input is outside its supported range.

The source's Lua number operations are exact over this domain. Every `n` is an exactly representable integer; multiplying it by a power of two only changes its binary exponent, and dividing by a power of two retains the exact fractional bits needed by `floor`. The remainder by `2^53` selects the low 53 bits. The ports express the same operation with integer bit slices: retain the low `53-shift` bits, shift them left, and add the high `shift` bits rotated around.

The 53-bit width comes from the Lua source's `uint53` module. This is distinct from the 32-bit rotations in Java `BitRotate` and Python `rotate_bits`, and from rotating arrays. The source does not validate inputs; the shared contract provides finite unsigned bounds and an invalid sentinel.

The ABI is `int64_t circular_left_shift(uint64_t n, uint64_t shift)` and uses the existing `binary_scalar` family.

## Workload

[`workload.json`](workload.json) covers both shift endpoints, zero, wraparound of high bits, the maximum uint53 value, and out-of-domain words.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/circular_left_shift.c`](../../../c/c/circular_left_shift.c) |
| C3 | [`c3/c/circular_left_shift.c3`](../../../c3/c/circular_left_shift.c3) |
| C++ | [`cpp/c/circular_left_shift.cpp`](../../../cpp/c/circular_left_shift.cpp) |
| Elisa | [`elisa/c/circular_left_shift.elisa`](../../../elisa/c/circular_left_shift.elisa) |
| Nim | [`nim/c/circular_left_shift.nim`](../../../nim/c/circular_left_shift.nim) |
| Odin | [`odin/c/circular_left_shift.odin`](../../../odin/c/circular_left_shift.odin) |
| Rust | [`rust/c/circular_left_shift.rs`](../../../rust/c/circular_left_shift.rs) |
| V | [`v/c/circular_left_shift.v`](../../../v/c/circular_left_shift.v) |
| Zig | [`zig/c/circular_left_shift.zig`](../../../zig/c/circular_left_shift.zig) |

## Upstream source

- [TheAlgorithms/Lua `circular_left_shift.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/circular_left_shift.lua)
- [TheAlgorithms/Java `BitRotate.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BitRotate.java) is a separate 32-bit rotation API.
- [TheAlgorithms/Python `rotate_bits.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/rotate_bits.py) is a separate 32-bit rotation API.
