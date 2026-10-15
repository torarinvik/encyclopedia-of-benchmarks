/// Reverse the bit order of an unsigned 32-bit word.
export fn reverse_bits(value: i64) i64 {
    if (value < 0 or value > 4294967295) return -1;
    var remaining: u32 = @intCast(value);
    var reversed: u32 = 0;
    for (0..32) |_| {
        reversed = (reversed << 1) | (remaining & 1);
        remaining >>= 1;
    }
    return @intCast(reversed);
}
