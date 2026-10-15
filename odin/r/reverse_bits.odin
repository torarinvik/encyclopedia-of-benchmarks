package reverse_bits

// Reverse the bit order of an unsigned 32-bit word.
@(export)
reverse_bits :: proc "c" (value: i64) -> i64 {
    if value < 0 || value > 4_294_967_295 do return -1
    remaining := u32(value)
    reversed: u32 = 0
    for bit := 0; bit < 32; bit += 1 {
        reversed = (reversed << 1) | (remaining & 1)
        remaining = remaining >> 1
    }
    return i64(reversed)
}
