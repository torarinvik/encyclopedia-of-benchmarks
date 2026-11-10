package hamming_weight

import "core:math/bits"

// Count set bits in an unsigned 32-bit integer.
@(export)
hamming_weight :: proc "c" (value: i64) -> i64 {
    if value < 0 || value > 4_294_967_295 do return -1
    return i64(bits.count_ones(u32(value)))
}
