const std = @import("std");

const max_simulations: usize = 32;
const max_parseable_input_length: usize = 520;

fn allowedMaturity(value: f64) bool {
    return value == 0.25 or value == 0.5 or value == 1.0 or value == 2.0;
}

fn allowedStepCount(value: f64) bool {
    return value == 1.0 or value == 2.0 or value == 4.0 or value == 8.0 or value == 16.0;
}

export fn monte_carlo_simulation(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 7 or input_length > max_parseable_input_length) return -1;
    for (0..input_length) |index| {
        if (!std.math.isFinite(values[index])) return -1;
    }

    const s0 = values[0];
    const strike = values[1];
    const rate = values[2];
    const volatility = values[3];
    const maturity = values[4];
    const step_value = values[5];
    const simulation_value = values[6];
    if (s0 < 1.0 or s0 > 1000.0 or strike < 0.0 or strike > 2000.0 or
        rate < -0.25 or rate > 0.25 or volatility < 0.0 or volatility > 0.5 or
        !allowedMaturity(maturity) or !allowedStepCount(step_value) or
        simulation_value < 1.0 or simulation_value > @as(f64, @floatFromInt(max_simulations)) or
        @trunc(simulation_value) != simulation_value) return -1;

    const steps: usize = @intFromFloat(step_value);
    const simulations: usize = @intFromFloat(simulation_value);
    if (input_length != 7 + steps * simulations) return -1;
    for (7..input_length) |index| {
        if (values[index] < -3.0 or values[index] > 3.0) return -1;
    }

    const dt = maturity / @as(f64, @floatFromInt(steps));
    const sqrt_dt = @sqrt(dt);
    const drift_rate = rate - 0.5 * (volatility * volatility);
    const drift = drift_rate * maturity;
    var payoffs = [_]f64{0.0} ** max_simulations;
    for (0..simulations) |simulation| {
        var brownian = 0.0;
        const offset = 7 + simulation * steps;
        for (0..steps) |step| {
            brownian += sqrt_dt * values[offset + step];
        }
        const exponent = drift + volatility * brownian;
        const terminal_price = s0 * @exp(exponent);
        const difference = terminal_price - strike;
        payoffs[simulation] = if (difference > 0.0) difference else 0.0;
    }

    var total = 0.0;
    for (0..simulations) |simulation| {
        total += payoffs[simulation];
    }
    const option_price = (total / @as(f64, @floatFromInt(simulations))) * @exp(-rate * maturity);
    if (!std.math.isFinite(option_price)) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    out[0] = option_price;
    return 1;
}
