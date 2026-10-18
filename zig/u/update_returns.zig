const std = @import("std");

const MIN_RETURNS: usize = 2;
const MAX_RETURNS: usize = 60;
const MAX_INPUT_LENGTH: usize = 62;
const MAX_OUTPUT_LENGTH: usize = 63;
const Z_95: f64 = 1.6448536269514722;

export fn update_returns(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, output_capacity: usize) i64 {
    const values = input_opt orelse return -1;
    if (input_length < 1 + MIN_RETURNS or input_length > MAX_INPUT_LENGTH) return -1;
    for (0..input_length) |index| {
        if (!std.math.isFinite(values[index])) return -1;
    }

    const count_value = values[0];
    if (@trunc(count_value) != count_value or
        count_value < @as(f64, @floatFromInt(MIN_RETURNS)) or
        count_value > @as(f64, @floatFromInt(MAX_RETURNS))) return -1;
    const count: usize = @intFromFloat(count_value);
    if (input_length != count + 1) return -1;

    var returns: [MAX_RETURNS]f64 = undefined;
    var sum: f64 = 0.0;
    for (0..count) |index| {
        const value = values[index + 1];
        if (value < -0.25 or value > 0.25) return -1;
        returns[index] = value;
        sum += value;
    }
    const mean = sum / @as(f64, @floatFromInt(count));
    var squared_deviation_sum: f64 = 0.0;
    for (0..count) |index| {
        const deviation = returns[index] - mean;
        squared_deviation_sum += deviation * deviation;
    }
    const volatility = @sqrt(squared_deviation_sum / @as(f64, @floatFromInt(count - 1)));
    if (!std.math.isFinite(mean) or !std.math.isFinite(volatility) or volatility == 0.0) return -1;

    const var_value = 100000.0 * (Z_95 * volatility - mean);
    if (!std.math.isFinite(var_value)) return -1;

    var staged: [MAX_OUTPUT_LENGTH]f64 = undefined;
    for (0..count) |index| staged[index] = returns[index];
    staged[count] = mean;
    staged[count + 1] = volatility;
    staged[count + 2] = var_value;
    const result_length = count + 3;

    const output = output_opt orelse return -2;
    if (output_capacity < result_length) return -2;
    for (0..result_length) |index| output[index] = staged[index];
    return @intCast(result_length);
}
