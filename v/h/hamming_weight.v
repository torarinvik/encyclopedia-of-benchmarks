module hamming_weight

import math.bits

// Count set bits in an unsigned 32-bit integer.
@[export: 'hamming_weight']
pub fn hamming_weight(value i64) i64 {
    if value < 0 || value > 4_294_967_295 { return -1 }
    return i64(bits.ones_count_32(u32(value)))
}
