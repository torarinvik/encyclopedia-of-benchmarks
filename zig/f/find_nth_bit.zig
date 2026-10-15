const MAX_NUM: u64 = 2_147_483_647;
const INVALID_RESULT: i64 = -1;

export fn find_nth_bit(num: u64, n: u64) i64 {
    if (num > MAX_NUM or n < 1 or n > 31) return INVALID_RESULT;
    const value: i32 = @intCast(num);
    const shift: u5 = @intCast(n - 1);
    return @as(i64, @intCast((value & (@as(i32, 1) << shift)) >> shift));
}
