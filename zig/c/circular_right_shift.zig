/// Rotate an unsigned 53-bit integer right by 0 through 53 positions.
export fn circular_right_shift(value: u64, shift: u64) i64 {
    const mask: u64 = 9_007_199_254_740_991;
    if (value > mask or shift > 53) return -1;
    const left_amount: u6 = @intCast(53 - shift);
    const amount: u6 = @intCast(shift);
    const low_mask = mask >> left_amount;
    const low = (value & low_mask) << left_amount;
    const high = value >> amount;
    return @intCast(low | high);
}
