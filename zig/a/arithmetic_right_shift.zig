const MAX_U53: u64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = -1;

export fn arithmetic_right_shift(n: u64, shift: u64) i64 {
    if (n > MAX_U53 or shift > 53) return INVALID_RESULT;
    const count: u6 = @intCast(shift);
    const low_count: u6 = @intCast(53 - shift);
    const low_mask = (@as(u64, 1) << low_count) - 1;
    const shifted = n >> count;
    const fill_mask = if ((n >> 52) != 0) MAX_U53 ^ low_mask else 0;
    return @intCast(fill_mask | shifted);
}
