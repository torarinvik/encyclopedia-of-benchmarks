/// Rotate an unsigned 53-bit integer left by 0 through 53 positions.
export fn circular_left_shift(value: u64, shift: u64) i64 {
    const mask: u64 = 9_007_199_254_740_991;
    if (value > mask or shift > 53) return -1;
    const low = (value & (mask >> @intCast(shift))) << @intCast(shift);
    const high = value >> @intCast(53 - shift);
    return @intCast(low | high);
}
