package bit_swap

import "core:c"

// Swap two 0-based bits in a signed 32-bit value.
@(export)
bit_swap :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 3 do return -2_147_483_649
    data := values[0]
    pos_a := values[1]
    pos_b := values[2]
    if data < -2_147_483_648 || data > 2_147_483_647 || pos_a < 0 || pos_a >= 32 || pos_b < 0 || pos_b >= 32 do return -2_147_483_649
    bits := data & i64(0xFFFF_FFFF)
    mask_a := i64(1) << u32(pos_a)
    mask_b := i64(1) << u32(pos_b)
    bit_a := (bits >> u32(pos_a)) & 1
    bit_b := (bits >> u32(pos_b)) & 1
    if bit_a != bit_b do bits = bits ^ mask_a ^ mask_b
    if bits >= 2_147_483_648 do return bits - 4_294_967_296
    return bits
}
