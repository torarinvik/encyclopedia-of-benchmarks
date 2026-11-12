const std = @import("std");

const MAX_STEPS: usize = 8;
const MAX_FACTORS: usize = 3;

export fn hjm_forward_path(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 7 or input_length > 54) return -1;
    const steps_value = values[0];
    const factors_value = values[1];
    if (!std.math.isFinite(steps_value) or @trunc(steps_value) != steps_value
        or steps_value < 2 or steps_value > MAX_STEPS) return -1;
    if (!std.math.isFinite(factors_value) or @trunc(factors_value) != factors_value
        or factors_value < 1 or factors_value > MAX_FACTORS) return -1;
    const steps: usize = @intFromFloat(steps_value);
    const factors: usize = @intFromFloat(factors_value);
    const years = values[2];
    if (years != 1.0 and years != 2.0 and years != 3.0) return -1;
    if (input_length != 3 + steps + 2 * factors * (steps - 1)) return -1;

    var yields = [_]f64{0} ** MAX_STEPS;
    var vols = [_]f64{0} ** (MAX_FACTORS * (MAX_STEPS - 1));
    var shocks = [_]f64{0} ** ((MAX_STEPS - 1) * MAX_FACTORS);
    var forwards = [_]f64{0} ** MAX_STEPS;
    var factor_drifts = [_]f64{0} ** (MAX_FACTORS * (MAX_STEPS - 1));
    var total_drifts = [_]f64{0} ** (MAX_STEPS - 1);
    var path = [_]f64{0} ** (MAX_STEPS * MAX_STEPS);

    var cursor: usize = 3;
    for (0..steps) |maturity| {
        const value = values[cursor];
        cursor += 1;
        if (!std.math.isFinite(value) or value < -0.05 or value > 0.20) return -1;
        yields[maturity] = value;
    }
    for (0..factors) |factor| {
        for (0..steps - 1) |maturity| {
            const value = values[cursor];
            cursor += 1;
            if (!std.math.isFinite(value) or value < 0 or value > 0.30) return -1;
            vols[factor * (MAX_STEPS - 1) + maturity] = value;
        }
    }
    for (0..steps - 1) |time| {
        for (0..factors) |factor| {
            const value = values[cursor];
            cursor += 1;
            if (!std.math.isFinite(value) or value < -3 or value > 3) return -1;
            shocks[time * MAX_FACTORS + factor] = value;
        }
    }

    const dt = years / @as(f64, @floatFromInt(steps));
    forwards[0] = yields[0];
    for (1..steps) |maturity| {
        forwards[maturity] = @as(f64, @floatFromInt(maturity + 1)) * yields[maturity]
            - @as(f64, @floatFromInt(maturity)) * yields[maturity - 1];
    }
    for (0..factors) |factor| {
        const base = factor * (MAX_STEPS - 1);
        factor_drifts[base] = 0.5 * dt * vols[base] * vols[base];
        for (1..steps - 1) |maturity| {
            var drift: f64 = 0;
            for (0..maturity) |prior| drift -= factor_drifts[base + prior];
            var prefix_volatility: f64 = 0;
            for (0..maturity + 1) |prior| prefix_volatility += vols[base + prior];
            drift += 0.5 * dt * prefix_volatility * prefix_volatility;
            factor_drifts[base + maturity] = drift;
        }
    }
    for (0..steps - 1) |maturity| {
        for (0..factors) |factor| {
            total_drifts[maturity] += factor_drifts[factor * (MAX_STEPS - 1) + maturity];
        }
    }
    for (0..steps) |maturity| path[maturity] = forwards[maturity];
    const root_dt = @sqrt(dt);
    for (1..steps) |time| {
        for (0..steps - time) |maturity| {
            var total_shock: f64 = 0;
            for (0..factors) |factor| {
                total_shock += vols[factor * (MAX_STEPS - 1) + maturity]
                    * shocks[(time - 1) * MAX_FACTORS + factor];
            }
            path[time * steps + maturity] = path[(time - 1) * steps + maturity + 1]
                + total_drifts[maturity] * dt + root_dt * total_shock;
        }
    }

    const needed = steps * steps;
    const out = output orelse return -2;
    if (output_capacity < needed) return -2;
    for (0..needed) |index| out[index] = path[index];
    return @intCast(needed);
}
