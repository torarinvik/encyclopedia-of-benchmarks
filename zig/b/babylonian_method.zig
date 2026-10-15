export fn babylonian_method(input: f64) f64 {
    if (!(input >= 2.0 and input <= 999_999.0)) return -1.0;
    const radicand: i64 = @intFromFloat(input);
    if (@as(f64, @floatFromInt(radicand)) != input) return -1.0;
    var i: i64 = 1;
    while (i * i <= radicand) : (i += 1) {}
    i -= 1;
    if (i * i == radicand) return -1.0;
    const x0: f64 = @floatFromInt(i);
    return (input / x0 + x0) / 2.0;
}
