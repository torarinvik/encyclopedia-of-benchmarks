package hamming_weight

// Count set bits in an unsigned 32-bit integer.
@(export)
hamming_weight :: proc "c" (value: i64) -> i64 {
    if value < 0 || value > 4_294_967_295 do return -1
    number := u32(value)
    count: i64 = 0
    for bit := 0; bit < 32; bit += 1 {
        count += i64((number >> u32(bit)) & 1)
    }
    return count
}
