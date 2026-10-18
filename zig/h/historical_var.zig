const std = @import("std");

export fn historical_var(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 24 or input_length > 69) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const portfolio_value = values[0];
    const confidence_level = values[1];
    const time_horizon = values[2];
    const count_value = values[3];
    if (@trunc(count_value) != count_value or count_value < 20 or count_value > 64) return -1;
    const return_count: usize = @intFromFloat(count_value);
    if (input_length != 4 + return_count or portfolio_value < 100 or portfolio_value > 1_000_000 or
        confidence_level < 0.5 or confidence_level > 0.95 or time_horizon < 1 or time_horizon > 10) return -1;
    var sorted_returns = [_]f64{0} ** 64;
    for (0..return_count) |i| {
        const value = values[4 + i];
        if (value < -0.25 or value > 0.25) return -1;
        var position = i;
        while (position > 0 and sorted_returns[position - 1] > value) : (position -= 1) {
            sorted_returns[position] = sorted_returns[position - 1];
        }
        sorted_returns[position] = value;
    }
    const index: usize = @intFromFloat(@floor((1.0 - confidence_level) * @as(f64, @floatFromInt(return_count))));
    if (index < 1) return -1;
    const result = -sorted_returns[index - 1] * portfolio_value * @sqrt(time_horizon);
    const out = output orelse return -2;
    if (capacity < 1) return -2;
    out[0] = result;
    return 1;
}
