/// Solve Boyle's law for one omitted variable, rounded to 3 decimals.
fn roundedMilli(numerator: i64, denominator: i64) i64 {
    const scaled = numerator * 1000;
    var quotient = @divTrunc(scaled, denominator);
    const remainder = @rem(scaled, denominator);
    if (2 * remainder > denominator or (2 * remainder == denominator and @rem(quotient, 2) != 0)) quotient += 1;
    return quotient;
}

export fn boyles_law(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return -1.0e300;
    const target = values[0];
    const a = values[1];
    const b = values[2];
    const c = values[3];
    if (target < 0 or target > 3 or a < 1 or a > 1000 or b < 1 or b > 1000 or c < 1 or c > 1000)
        return -1.0e300;
    var numerator: i64 = undefined;
    var denominator: i64 = undefined;
    switch (target) {
        0 => { numerator = c * a; denominator = b; },
        1 => { numerator = b * a; denominator = c; },
        2 => { numerator = c * b; denominator = a; },
        else => { numerator = c * a; denominator = b; },
    }
    return @as(f64, @floatFromInt(roundedMilli(numerator, denominator))) / 1000.0;
}
