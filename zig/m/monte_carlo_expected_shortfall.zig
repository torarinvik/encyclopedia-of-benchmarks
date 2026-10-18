const std = @import("std");

const min_returns: usize = 20;
const max_returns: usize = 64;
const min_simulations: usize = 20;
const max_simulations: usize = 128;
const max_valid_input_length: usize = 197;
const max_parseable_input_length: usize = 198;

export fn monte_carlo_expected_shortfall(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 45 or input_length > max_parseable_input_length) return -1;
    for (0..input_length) |index| {
        if (!std.math.isFinite(values[index])) return -1;
    }
    const portfolio = values[0];
    const confidence = values[1];
    const horizon = values[2];
    const simulation_value = values[3];
    const return_count_value = values[4];
    if (portfolio < 100.0 or portfolio > 1_000_000.0 or confidence < 0.5 or confidence > 0.95 or
        horizon < 1.0 or horizon > 10.0 or simulation_value < @as(f64, @floatFromInt(min_simulations)) or
        simulation_value > @as(f64, @floatFromInt(max_simulations)) or
        return_count_value < @as(f64, @floatFromInt(min_returns)) or
        return_count_value > @as(f64, @floatFromInt(max_returns)) or
        @trunc(simulation_value) != simulation_value or @trunc(return_count_value) != return_count_value) return -1;
    const simulation_count: usize = @intFromFloat(simulation_value);
    const return_count: usize = @intFromFloat(return_count_value);
    if (input_length != 5 + return_count + simulation_count or input_length > max_valid_input_length) return -1;

    var returns = [_]f64{0.0} ** max_returns;
    var simulated = [_]f64{0.0} ** max_simulations;
    var sum = 0.0;
    for (0..return_count) |index| {
        const value = values[5 + index];
        if (value < -0.25 or value > 0.25) return -1;
        returns[index] = value;
        sum += value;
    }
    for (0..simulation_count) |index| {
        const z = values[5 + return_count + index];
        if (z < -3.0 or z > 3.0) return -1;
        simulated[index] = z;
    }
    const mean = sum / @as(f64, @floatFromInt(return_count));
    var squared_deviation = 0.0;
    for (0..return_count) |index| {
        const delta = returns[index] - mean;
        squared_deviation += delta * delta;
    }
    const volatility = @sqrt(squared_deviation / @as(f64, @floatFromInt(return_count - 1)));
    if (!std.math.isFinite(volatility) or volatility == 0.0) return -1;
    for (0..simulation_count) |index| {
        simulated[index] = mean + volatility * simulated[index];
    }
    for (1..simulation_count) |index| {
        const value = simulated[index];
        var position = index;
        while (position > 0 and simulated[position - 1] > value) {
            simulated[position] = simulated[position - 1];
            position -= 1;
        }
        simulated[position] = value;
    }

    const tail_value = @floor((1.0 - confidence) * @as(f64, @floatFromInt(simulation_count)));
    if (tail_value < 1.0 or tail_value > @as(f64, @floatFromInt(simulation_count))) return -1;
    const tail_count: usize = @intFromFloat(tail_value);
    var tail_sum = 0.0;
    for (0..tail_count) |index| tail_sum += simulated[index];
    const metric = -(tail_sum / @as(f64, @floatFromInt(tail_count))) * portfolio * @sqrt(horizon);
    if (!std.math.isFinite(metric)) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    out[0] = metric;
    return 1;
}
