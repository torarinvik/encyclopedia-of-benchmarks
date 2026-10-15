/// Exact square-pyramidal sum within the pinned u64 intermediate range.
export fn square_pyramidal_numbers(n: i64) i64 {
    if (n < 0 or n > 2_097_151) return -1;
    const value: u64 = @intCast(n);
    const numerator = value * (value + 1) * (2 * value + 1);
    return @intCast(numerator / 6);
}
