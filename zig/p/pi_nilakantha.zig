export fn pi_nilakantha(input: f64) f64 {
    if (!(input >= 0.0 and input <= 500.0 and input == @as(f64, @floatFromInt(@as(i32, @intFromFloat(input)))))) return -1.0;
    const iterations: i32 = @intFromFloat(input);
    var pi: f64 = 3.0;
    var div_counter: i32 = 2;
    var i: i32 = 0;
    while (i < iterations) : (i += 1) {
        const denominator = div_counter * (div_counter + 1) * (div_counter + 2);
        const term = 4.0 / @as(f64, @floatFromInt(denominator));
        if (@mod(i, 2) == 0) pi = pi + term else pi = pi - term;
        div_counter += 2;
    }
    return pi;
}
