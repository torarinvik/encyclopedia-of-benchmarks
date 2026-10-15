module hamming_weight

// Count set bits in an unsigned 32-bit integer.
@[export: 'hamming_weight']
pub fn hamming_weight(value i64) i64 {
    if value < 0 || value > 4_294_967_295 { return -1 }
    number := u32(value)
    mut count := i64(0)
    for bit in 0 .. 32 {
        count += i64((number >> u32(bit)) & 1)
    }
    return count
}
