const INVALID: f64 = -1.0e300;
export fn fractional_differentiation(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 4 or length > 18) return INVALID;
    const d_units = values[0]; const wv = values[1]; const n = length - 2;
    if (d_units < 0 or d_units > 1000000 or wv < 1 or wv > 8 or n <= @as(usize, @intCast(wv)) or n > 16) return INVALID;
    for (0..n) |i| { if (values[2+i] < -1000000 or values[2+i] > 1000000) return INVALID; }
    const w: usize = @intCast(wv); const d = @as(f64, @floatFromInt(d_units)) / 1000000.0;
    var weights: [8]f64 = undefined; weights[0] = 1.0;
    for (1..w) |k| weights[k] = -weights[k-1] * (d - @as(f64, @floatFromInt(k)) + 1.0) / @as(f64, @floatFromInt(k));
    var result: f64 = 0.0;
    for (0..w) |j| result += weights[j] * (@as(f64, @floatFromInt(values[2+n-1-j])) / 1000.0);
    return result;
}
