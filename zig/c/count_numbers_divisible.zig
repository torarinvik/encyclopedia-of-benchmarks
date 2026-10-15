/// Count multiples of divisor in the inclusive positive integer interval [first, last].
export fn count_numbers_divisible(first: f64, last: f64, divisor: f64) f64 {
    const a: i64 = @intFromFloat(first);
    const b: i64 = @intFromFloat(last);
    const m: i64 = @intFromFloat(divisor);
    return @floatFromInt(@divTrunc(b, m) - @divTrunc(a - 1, m));
}
