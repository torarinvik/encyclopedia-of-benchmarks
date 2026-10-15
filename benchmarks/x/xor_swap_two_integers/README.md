# XOR swap two integers

This benchmark ports the pinned Python `xor_swap(a, b)` routine, which applies the three XOR assignments and returns the swapped pair.

## Contract

- The binary scalar ABI accepts two signed 16-bit values, `a` and `b`.
- The returned pair is packed as `(swapped_a + 32768) * 65536 + (swapped_b + 32768)`. Each offset value fits an unsigned 16-bit field, so the packed result fits in signed 64-bit range.
- Inputs outside `[-32768, 32767]` return `-1`.

[`workload.json`](workload.json) covers the in-range pinned examples, equal values, both signed 16-bit extremes, and invalid inputs. The source's `xor_swap(12345, 54321)` example is outside this bounded benchmark domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/x/xor_swap_two_integers.c`](../../../c/x/xor_swap_two_integers.c) |
| C3 | [`c3/x/xor_swap_two_integers.c3`](../../../c3/x/xor_swap_two_integers.c3) |
| C++ | [`cpp/x/xor_swap_two_integers.cpp`](../../../cpp/x/xor_swap_two_integers.cpp) |
| Elisa | [`elisa/x/xor_swap_two_integers.elisa`](../../../elisa/x/xor_swap_two_integers.elisa) |
| Nim | [`nim/x/xor_swap_two_integers.nim`](../../../nim/x/xor_swap_two_integers.nim) |
| Odin | [`odin/x/xor_swap_two_integers.odin`](../../../odin/x/xor_swap_two_integers.odin) |
| Rust | [`rust/x/xor_swap_two_integers.rs`](../../../rust/x/xor_swap_two_integers.rs) |
| V | [`v/x/xor_swap_two_integers.v`](../../../v/x/xor_swap_two_integers.v) |
| Zig | [`zig/x/xor_swap_two_integers.zig`](../../../zig/x/xor_swap_two_integers.zig) |

## Upstream source

- [TheAlgorithms/Python `xor_swap_two_integers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/xor_swap_two_integers.py)
