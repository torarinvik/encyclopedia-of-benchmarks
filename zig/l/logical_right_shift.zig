const MAX_U53: u64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = -1;

export fn logical_right_shift(n: u64, shift: u64) i64 {
    if (n > MAX_U53 or shift > 53) return INVALID_RESULT;
    const count: u6 = @intCast(shift);
    return @intCast(n >> count);
}
