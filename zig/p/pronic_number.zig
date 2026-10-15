/// Check whether n is the product of two consecutive nonnegative integers.
export fn pronic_number(n: i64) i64 {
    if (n < 0 or n > 2_147_483_647) return -1;
    const root: i64 = @intFromFloat(@sqrt(@as(f64, @floatFromInt(n))));
    return if (root * (root + 1) == n) 1 else 0;
}
