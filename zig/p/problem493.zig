fn chooseTen(n: i64) i64 {
    var result: i64 = 1;
    for (0..10) |i| result = @divTrunc(result * (n - @as(i64, @intCast(i))), @as(i64, @intCast(i + 1)));
    return result;
}

export fn problem493(picks: i64) i64 {
    if (picks < 0 or picks > 70) return -1;
    const denominator = chooseTen(70);
    const missing: i64 = if (picks > 60) 0 else chooseTen(70 - picks);
    const numerator = 7 * (denominator - missing);
    const whole = @divTrunc(numerator, denominator);
    var remainder = @rem(numerator, denominator);
    var fraction: i64 = 0;
    for (0..9) |_| {
        remainder *= 10;
        fraction = fraction * 10 + @divTrunc(remainder, denominator);
        remainder = @rem(remainder, denominator);
    }
    remainder *= 10;
    const guard = @divTrunc(remainder, denominator);
    remainder = @rem(remainder, denominator);
    var scaled = whole * 1_000_000_000 + fraction;
    if (guard > 5 or (guard == 5 and (remainder > 0 or @rem(scaled, 2) != 0))) scaled += 1;
    return scaled;
}
